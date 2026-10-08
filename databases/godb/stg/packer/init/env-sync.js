// Run by env-sync.sh through mongosh. Documents stay BSON throughout the copy.
const env = process.env;
const MAX_BATCH_BYTES = 8 * 1024 * 1024;
const WRITE_CONCERN = { w: 'majority', wtimeout: 60000 };
const TRANSIENT_CODES = new Set([6, 7, 89, 91, 189, 262, 9001, 10107, 11600, 11602, 13435, 13436]);

/**
 * Write a status message to stderr, keeping stdout available for the Bash plan.
 */
function log(message) {
  process.stderr.write(`${message}\n`);
}

/**
 * Read a positive integer environment setting, falling back when unset.
 * Throw if the value exceeds the supplied maximum or is not a positive integer.
 */
function readInteger(name, fallback, maximum) {
  const value = Number(env[name] || fallback);
  if (!Number.isInteger(value) || value < 1 || value > maximum) {
    throw new Error(`${name} must be an integer between 1 and ${maximum}`);
  }
  return value;
}

/**
 * Parse a comma- or newline-separated setting into trimmed, nonempty strings.
 */
function parseList(value) {
  return (value || '').split(/[\n,]/).map(item => item.trim()).filter(Boolean);
}

/**
 * Compile a collection name or namespace glob into an anchored RegExp.
 * Only * acts as a wildcard; bare collection names match in every database.
 */
function compileExclusion(pattern) {
  const namespace = pattern.includes('.') ? pattern : `*.${pattern}`;
  const regex = namespace.split('*')
    .map(part => part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('.*');
  return new RegExp(`^${regex}$`);
}

/**
 * Validate environment settings and return the action, batch/retry limits,
 * namespace mappings, exclusion patterns and databases omitted from discovery.
 */
function readConfig() {
  const batchSize = readInteger('SYNC_BATCH_SIZE', 500, 10000);
  const attempts = readInteger('SYNC_MAX_ATTEMPTS', 3, 10);
  const delay = readInteger('SYNC_RETRY_DELAY_MS', 5000, 60000);
  if (!['plan', 'upsert'].includes(env.ENV_SYNC_ACTION)) throw new Error('Invalid ENV_SYNC_ACTION');
  if (!env.SOURCE_URI || !env.DESTINATION_URI) throw new Error('Source and destination URIs are required');
  if (env.SOURCE_URI === env.DESTINATION_URI) throw new Error('Source and destination URIs must differ');
  return {
    action: env.ENV_SYNC_ACTION,
    batchSize, attempts, delay,
    mappings: parseList(env.ENV_SYNC_COLLECTIONS),
    excluded: parseList(env.EXCLUDED_COLLECTIONS).map(compileExclusion),
    systemDatabases: new Set(parseList(env.ENV_SYNC_SYSTEM_DATABASES)),
  };
}

/**
 * Return whether a MongoDB error is safe to retry.
 * A bulk error is retryable only when all reported write failures are transient.
 */
function isTransient(error) {
  const writes = error.writeErrors || error.result?.getWriteErrors?.() || [];
  if (writes.length) return writes.every(write => TRANSIENT_CODES.has(write.code));
  return TRANSIENT_CODES.has(error.code) ||
    error.hasErrorLabel?.('RetryableWriteError') ||
    /Mongo(Network|ServerSelection)/.test(error.name || '');
}

/**
 * Run an async operation within config.attempts, waiting config.delay milliseconds
 * between transient failures. Return its result or propagate the final error.
 * The caller must ensure replaying the operation is safe.
 */
async function retry(config, label, operation) {
  for (let attempt = 1; ; attempt++) {
    try { return await operation(); }
    catch (error) {
      if (!isTransient(error) || attempt >= config.attempts) throw error;
      log(`${label}: transient MongoDB failure; retry ${attempt}/${config.attempts - 1} in ${config.delay}ms`);
      await sleep(config.delay);
    }
  }
}

/**
 * Check that the destination is a writable primary or mongos router.
 * Throw a retryable NotWritablePrimary error when the connected node cannot write.
 */
async function requireWritable(destination) {
  const hello = await destination.getDB('admin').runCommand({ hello: 1 });
  if (hello.isWritablePrimary || hello.msg === 'isdbgrid') return;
  const error = new Error('Destination is not writable. For a direct SSH connection, forward the current primary; otherwise use a reachable replica-set seed list.');
  error.code = 10107;
  throw error;
}

/**
 * Connect using the environment URIs and check destination writability.
 * Return the source and destination handles after bounded connection retries.
 */
async function connectDatabases(config) {
  const source = await retry(config, 'Connect source', () => new Mongo(env.SOURCE_URI));
  const destination = await retry(config, 'Connect destination', () => new Mongo(env.DESTINATION_URI));
  await retry(config, 'Destination preflight', () => requireWritable(destination));
  return { source, destination };
}

/**
 * Validate an exact db.collection namespace and return [database, collection].
 * Split at the first dot so collection names may themselves contain dots.
 */
function splitNamespace(namespace) {
  const dot = namespace.indexOf('.');
  if (dot < 1 || dot === namespace.length - 1 || /[\t\r\n*:]/.test(namespace)) {
    throw new Error(`Invalid namespace: ${namespace}`);
  }
  return [namespace.slice(0, dot), namespace.slice(dot + 1)];
}

/**
 * Parse db.collection or srcDb.collection:destDb.collection into namespace fields.
 * Without an explicit destination, preserve the source namespace.
 */
function parseMapping(mapping) {
  const parts = mapping.split(':');
  if (parts.length > 2) throw new Error(`Invalid mapping: ${mapping}`);
  const [srcDB, srcColl] = splitNamespace(parts[0]);
  const [destDB, destColl] = splitNamespace(parts[1] || parts[0]);
  return { srcDB, srcColl, destDB, destColl };
}

/**
 * List source collections as identity mappings, omitting the supplied system
 * databases, views and internal system.* collections. Does not read documents.
 */
async function discoverMappings(source, systemDatabases) {
  const databases = await source.getDB('admin').runCommand({ listDatabases: 1, nameOnly: true });
  if (!databases.ok) throw new Error('Cannot list source databases');
  const mappings = [];
  for (const database of databases.databases) {
    if (systemDatabases.has(database.name)) continue;
    const collections = await source.getDB(database.name).getCollectionInfos();
    for (const collection of collections) {
      if (collection.type === 'view' || collection.name.startsWith('system.')) continue;
      mappings.push(`${database.name}.${collection.name}`);
    }
  }
  return mappings;
}

/**
 * Validate a plan item against source metadata and the requested action.
 * Return its uncompressed data size in bytes; throw for missing or unsupported collections.
 */
async function inspectSource(source, item, action) {
  const { srcDB, srcColl } = item;
  const namespace = `${srcDB}.${srcColl}`;
  const database = source.getDB(srcDB);
  const [info] = await database.getCollectionInfos({ name: srcColl });
  if (!info || info.type === 'view') throw new Error(`Source collection missing or is a view: ${namespace}`);
  if (action === 'upsert' && (info.type === 'timeseries' || info.options?.timeseries || info.options?.capped)) {
    throw new Error(`Incremental upserts do not support time-series or capped collections: ${namespace}`);
  }
  const stats = await database.runCommand({ collStats: srcColl, scale: 1 });
  if (!stats.ok || !Number.isFinite(Number(stats.size))) throw new Error(`Cannot measure ${namespace}`);
  return Number(stats.size);
}

/**
 * Discover or parse mappings, apply source exclusions and reject duplicate targets.
 * Return validated plan items sorted globally by size, then source namespace.
 * Performs metadata reads only; no destination writes occur here.
 */
async function buildPlan(source, config) {
  const mappings = config.mappings.length ? config.mappings : await discoverMappings(source, config.systemDatabases);
  const plan = [];
  const targets = new Set();
  for (const mapping of mappings) {
    const item = parseMapping(mapping);
    const namespace = `${item.srcDB}.${item.srcColl}`;
    if (config.excluded.some(pattern => pattern.test(namespace))) {
      log(`Excluded ${namespace}`);
      continue;
    }
    const target = `${item.destDB}.${item.destColl}`;
    if (targets.has(target)) throw new Error(`Multiple mappings target ${target}`);
    targets.add(target);
    item.size = await inspectSource(source, item, config.action);
    plan.push(item);
  }
  return plan.sort((a, b) => a.size - b.size || `${a.srcDB}.${a.srcColl}`.localeCompare(`${b.srcDB}.${b.srcColl}`));
}

/**
 * Write plan items to stdout as tab-separated source/destination fields and size,
 * in the order expected by the Bash replace loop.
 */
function printPlan(plan) {
  for (const item of plan) {
    print([item.srcDB, item.srcColl, item.destDB, item.destColl, item.size].join('\t'));
  }
}

/**
 * Validate all upsert targets before copying, setting item.missing on each plan item.
 * Reject existing targets whose collection type or options do not support upserts.
 */
async function validateDestinations(destination, plan) {
  for (const item of plan) {
    const [info] = await destination.getDB(item.destDB).getCollectionInfos({ name: item.destColl });
    item.missing = !info;
    if (info && (info.type !== 'collection' || info.options?.timeseries || info.options?.capped)) {
      throw new Error(`Destination does not support upserts: ${item.destDB}.${item.destColl}`);
    }
  }
}

/**
 * Create a missing destination collection with default options and an _id index.
 * Recheck existence on each retry so a lost creation acknowledgement is safe to replay.
 */
async function createDestination(destination, item, config) {
  if (!item.missing) return;
  await retry(config, `${item.srcDB}.${item.srcColl} create destination`, async () => {
    await requireWritable(destination);
    const database = destination.getDB(item.destDB);
    // Recheck in case creation committed before losing its acknowledgement.
    if (!(await database.getCollectionInfos({ name: item.destColl })).length) {
      await database.runCommand({ create: item.destColl, writeConcern: WRITE_CONCERN });
    }
  });
}

/**
 * Build a replaceOne upsert keyed by the document’s _id, retaining BSON values.
 * Throw if _id is absent, using the source namespace to identify the bad document.
 */
function replacementOperation(document, namespace) {
  if (!Object.prototype.hasOwnProperty.call(document, '_id')) {
    throw new Error(`${namespace}: document has no _id`);
  }
  return { replaceOne: { filter: { _id: document._id }, replacement: document, upsert: true } };
}

/**
 * Write a nonempty batch as unordered replacements with majority acknowledgement.
 * Check writability before every attempt; matching by _id makes partial replay safe.
 */
async function writeBatch(destination, target, operations, namespace, config) {
  if (!operations.length) return;
  await retry(config, `${namespace} batch`, async () => {
    await requireWritable(destination);
    await target.bulkWrite(operations, { ordered: false, writeConcern: WRITE_CONCERN });
  });
}

/**
 * Consume a source cursor in batches bounded by count and BSON bytes.
 * Return the number of successfully upserted documents; the caller owns cursor cleanup.
 */
async function copyDocuments(cursor, destination, target, namespace, config) {
  let operations = [], bytes = 0, copied = 0;
  while (await cursor.hasNext()) {
    const document = await cursor.next();
    const operation = replacementOperation(document, namespace);
    const documentBytes = bsonsize(document);
    // Bound memory and operation count; allow a single large document.
    if (operations.length && (operations.length >= config.batchSize || bytes + documentBytes > MAX_BATCH_BYTES)) {
      await writeBatch(destination, target, operations, namespace, config);
      copied += operations.length;
      operations = [];
      bytes = 0;
    }
    operations.push(operation);
    bytes += documentBytes;
  }
  await writeBatch(destination, target, operations, namespace, config);
  return copied + operations.length;
}

/**
 * Create the target if needed, stream one source collection and log completion.
 * Disable BSON value promotion and close the cursor on success or failure.
 */
async function copyCollection(source, destination, item, config) {
  const { srcDB, srcColl, destDB, destColl, size } = item;
  const namespace = `${srcDB}.${srcColl}`;
  log(`  ${namespace} → ${destDB}.${destColl} (${size} bytes, upsert)`);
  await createDestination(destination, item, config);
  const cursor = await source.getDB(srcDB).getCollection(srcColl).find({}, undefined, {
    batchSize: config.batchSize, promoteValues: false, bsonRegExp: true,
  });
  const target = destination.getDB(destDB).getCollection(destColl);
  try {
    const copied = await copyDocuments(cursor, destination, target, namespace, config);
    log(`  Completed ${namespace}: ${copied} documents upserted`);
  } finally { await cursor.close(); }
}

/**
 * Coordinate configuration, connections and planning, then print the replace plan
 * or validate and upsert collections sequentially in the planned order.
 */
async function main() {
  const config = readConfig();
  const { source, destination } = await connectDatabases(config);
  const plan = await buildPlan(source, config);
  if (config.action === 'plan') return printPlan(plan);
  await validateDestinations(destination, plan);
  for (const item of plan) await copyCollection(source, destination, item, config);
}

/**
 * Redact configured URIs from an error message, log it and exit with status 1.
 */
function reportError(error) {
  let message = String(error.message || error);
  for (const uri of [env.SOURCE_URI, env.DESTINATION_URI]) {
    if (uri) message = message.split(uri).join('<redacted URI>');
  }
  log(`ERROR: ${message}`);
  process.exit(1);
}

// mongosh file execution requires await inside an async function.
(async () => {
  try { await main(); }
  catch (error) { reportError(error); }
})();
