// Ramps load on the API so the product-service HPA scales out.
import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'https://microservice-shop.localhost:30443';
const params = { timeout: '10s' };

export const options = {
  // The Gateway host name points at the kind node; the certificate is from the local CA.
  hosts: { [__ENV.HOST || 'microservice-shop.localhost']: __ENV.NODE_IP },
  insecureSkipTLSVerify: true,
  scenarios: {
    ramp: {
      executor: 'ramping-arrival-rate',
      startRate: 50,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 200,
      stages: [
        { target: 200, duration: '1m' },
        { target: 200, duration: '2m' },
        { target: 0, duration: '30s' },
      ],
    },
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/api/products`, params);
  check(res, { 'status is 200': (r) => r.status === 200 });
}
