// Steady load through the Gateway while a rolling update runs.
// Fails if a single request gets a 5xx or a connection error (status 0).
import http from 'k6/http';
import { check } from 'k6';
import { Counter } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'https://microservice-shop.localhost:30443';
const params = { timeout: '10s' };
const errors5xx = new Counter('errors_5xx');

export const options = {
  // The Gateway host name points at the kind node; the certificate is from the local CA.
  hosts: { [__ENV.HOST || 'microservice-shop.localhost']: __ENV.NODE_IP },
  insecureSkipTLSVerify: true,
  scenarios: {
    steady: {
      executor: 'constant-arrival-rate',
      rate: 50,
      timeUnit: '1s',
      duration: __ENV.DURATION || '90s',
      preAllocatedVUs: 20,
      maxVUs: 100,
    },
  },
  thresholds: {
    errors_5xx: ['count==0'],
    http_req_failed: ['rate==0'],
  },
};

export default function () {
  // Alternate between the API (product-service) and the page (frontend).
  const url = __ITER % 2 === 0 ? `${BASE_URL}/api/products` : `${BASE_URL}/`;
  const res = http.get(url, params);
  if (res.status === 0 || res.status >= 500) errors5xx.add(1);
  check(res, { 'status is 200': (r) => r.status === 200 });
}
