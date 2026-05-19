# Infrastructure deployment

GO needs to run somewhere. We took great care to ensure it can run anywhere.
However, since our cloud is OCI, you will find here configuration files with this particular vendor idioms.

This module includes the database infrastructure for GO. It includes configuration files and scripts to deploy the necessary infrastructure for GO to run in production and staging environments. The infrastructure is deployed using Terraform, and it includes setup resources such as VMs, load balancers, databases, and more.

It uses mongodb, clickhouse and redis. (postgres is currently not in use). Each database has its own configuration files and scripts to deploy and manage the database infrastructure. The databases are used to store and manage the data for GO, and they are optimized for different use cases such as analytical queries, caching, and more. Usage instructions can be found in the `prd (or stg)/databases/[DATABASE_NAME]/README.md` file.

We have a worker that runs every 1 minute to update the data in redis with the data from mongodb. This allows us to have a caching layer for non-authenticated users (general public) to improve the performance of our services. The user uses the public API that gets the data from redis while authenticated users get the data from mongodb.

```bash
                   Application
                        │
      ┌─────────────────┼───────────────┐
      │                 │               │
    Redis            MongoDB        ClickHouse
(Public API)    (Auth users API)    (Analytics)
```