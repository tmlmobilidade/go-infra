import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },
    { duration: '3m', target: 50 },

    { duration: '1m', target: 100 },
    { duration: '3m', target: 100 },

    { duration: '1m', target: 150 },
    { duration: '3m', target: 150 },

    { duration: '5m', target: 200 },
  ],

  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<3000'],
  },
};

const URL = 'https://motis.go.tmlmobilidade.pt/';

export default function () {
  const response = http.get(URL);

  check(response, {
    'status is 200': (r) => r.status === 200,
    'response received': (r) => r.body.length > 0,
  });
}

