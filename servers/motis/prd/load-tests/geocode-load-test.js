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

const places = [
  // Lisbon
  { lat: 38.7223, lon: -9.1393, text: 'alg' },
  { lat: 38.7169, lon: -9.1399, text: 'rossio' },
  { lat: 38.7078, lon: -9.1366, text: 'praça do comércio' },
  { lat: 38.7528, lon: -9.1498, text: 'campo grande' },
  { lat: 38.7489, lon: -9.1600, text: 'entrecampos' },

  // Cascais
  { lat: 38.6979, lon: -9.4215, text: 'cascais' },
  { lat: 38.6968, lon: -9.4205, text: 'estação' },

  // Sintra
  { lat: 38.8029, lon: -9.3817, text: 'sintra' },
  { lat: 38.7981, lon: -9.3890, text: 'estação' },

  // Almada
  { lat: 38.6790, lon: -9.1569, text: 'almada' },
  { lat: 38.6800, lon: -9.1580, text: 'metro' },

  // Setúbal
  { lat: 38.5244, lon: -8.8882, text: 'setubal' },
  { lat: 38.5250, lon: -8.8890, text: 'estação' },

  // Porto
  { lat: 41.1496, lon: -8.6109, text: 'porto' },
  { lat: 41.1456, lon: -8.6109, text: 'trindade' },
  { lat: 41.1486, lon: -8.5859, text: 'campanhã' },

  // Other Portuguese cities
  { lat: 40.6405, lon: -8.6538, text: 'aveiro' },
  { lat: 40.2110, lon: -8.4292, text: 'coimbra' },
  { lat: 39.7440, lon: -8.8070, text: 'leiria' },
  { lat: 39.8230, lon: -7.4900, text: 'castelo branco' },
  { lat: 38.5667, lon: -7.9000, text: 'évora' },
  { lat: 37.0194, lon: -7.9304, text: 'faro' },
];

const searchTerms = [
  'alg',
  'est',
  'metro',
  'station',
  'bus',
  'gare',
  'terminal',
  'center',
  'centro',
  'avenida',
  'rua',
  'praça',
];

const modes =
  'AIRPLANE,HIGHSPEED_RAIL,LONG_DISTANCE,NIGHT_RAIL,' +
  'COACH,RIDE_SHARING,REGIONAL_RAIL,SUBURBAN,SUBWAY,' +
  'TRAM,BUS,FERRY,ODM,FUNICULAR,AERIAL_LIFT,OTHER';

export default function () {
  // Random Portuguese location
  const place = places[Math.floor(Math.random() * places.length)];

  // Random search term
  const text = searchTerms[Math.floor(Math.random() * searchTerms.length)];

  const url =
    `${BASE_URL}/api/v1/geocode` +
    `?place=${place.lat},${place.lon}` +
    `&text=${encodeURIComponent(text)}` +
    `&language=en` +
    `&mode=${modes}`;

  const response = http.get(url);

  check(response, {
    'status 200': (r) => r.status === 200,
    'response received': (r) => r.body.length > 0,
  });
}
