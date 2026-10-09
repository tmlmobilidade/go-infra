import http from 'k6/http';
import { check } from 'k6';

export const options = {
    stages: [
        { duration: '1m', target: 100 },
        { duration: '3m', target: 100 },
    
        { duration: '1m', target: 200 },
        { duration: '5m', target: 200 },
    
        { duration: '1m', target: 250 },
        { duration: '5m', target: 250  },
    
        { duration: '1m', target: 300 },
      ],

  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<3000'],
  },
};

const BASE_URL = 'https://motis.go.tmlmobilidade.pt';

const routes = [
  // Known working pair from your request
  { from: 'GTFS_170233', to: 'GTFS_170473' },
  { from: 'GTFS_170473', to: 'GTFS_170233' },

  // Add more real pairs from your application:
  // Lisbon → another stop
  // { from: 'VALID_LISBON_STOP_ID', to: 'VALID_OTHER_STOP_ID' },

  // Cascais → Lisbon
  // { from: 'VALID_CASCAIS_STOP_ID', to: 'VALID_LISBON_STOP_ID' },

  // Sintra → Lisbon
  // { from: 'VALID_SINTRA_STOP_ID', to: 'VALID_LISBON_STOP_ID' },

  // Porto → another stop
  // { from: 'VALID_PORTO_STOP_ID', to: 'VALID_OTHER_STOP_ID' },

  // Coimbra → another stop
  // { from: 'VALID_COIMBRA_STOP_ID', to: 'VALID_OTHER_STOP_ID' },

  // Faro → another stop
  // { from: 'VALID_FARO_STOP_ID', to: 'VALID_OTHER_STOP_ID' },
];

const params = {
  headers: { Accept: 'application/json' },
  timeout: '30s',
};

export default function () {
  const route = routes[Math.floor(Math.random() * routes.length)];

  // Randomize planning time within the next 3 hours.
  const offsetMinutes = Math.floor(Math.random() * 180);
  const planTime = new Date(
    Date.now() + (60 + offsetMinutes) * 60 * 1000
  ).toISOString();

  // Vary some planning options between requests.
  const alternatives = [1, 2, 3][
    Math.floor(Math.random() * 3)
  ];

  const arriveBy = Math.random() < 0.5;

  const query = [
    `time=${encodeURIComponent(planTime)}`,
    `fromPlace=${encodeURIComponent(route.from)}`,
    `toPlace=${encodeURIComponent(route.to)}`,
    `arriveBy=${arriveBy}`,
    'withFares=true',
    `numLegAlternatives=${alternatives}`,
    'fastestDirectFactor=1.5',
    'joinInterlinedLegs=false',
    'maxMatchingDistance=250',
  ].join('&');

  const response = http.get(
    `${BASE_URL}/api/v6/plan?${query}`,
    params
  );

  check(response, {
    'status is 200': (r) => r.status === 200,
    'response is not empty': (r) => !!r.body && r.body.length > 0,
  });
}