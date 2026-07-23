import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp up to 100 users
    { duration: '5m', target: 100 }, // Stay at 100 users
    { duration: '2m', target: 200 }, // Ramp up to 200 users
    { duration: '5m', target: 200 }, // Stay at 200 users
    { duration: '2m', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
    errors: ['rate<0.1'], // Error rate must be below 10%
  },
};

const BASE_URL = 'http://localhost:8080/api/v1';

export function setup() {
  // Create test user and get token
  const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
    email: 'test@example.com',
    password: 'TestPassword123!'
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  const token = loginRes.json('token');
  return { token };
}

export default function(data) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${data.token}`,
  };

  // Test 1: Get users
  let res = http.get(`${BASE_URL}/users?page=1&limit=10`, { headers });
  check(res, {
    'get users status is 200': (r) => r.status === 200,
    'get users response time < 200ms': (r) => r.timings.duration < 200,
  }) || errorRate.add(1);

  sleep(1);

  // Test 2: Track analytics event
  res = http.post(`${BASE_URL}/analytics/events`, JSON.stringify({
    eventType: 'page_view',
    eventName: 'home_viewed',
    properties: { page: '/home' }
  }), { headers });

  check(res, {
    'track event status is 201': (r) => r.status === 201,
    'track event response time < 100ms': (r) => r.timings.duration < 100,
  }) || errorRate.add(1);

  sleep(1);

  // Test 3: Get analytics
  res = http.get(`${BASE_URL}/analytics/summary?startDate=2024-01-01&endDate=2024-12-31`, { headers });
  check(res, {
    'get analytics status is 200': (r) => r.status === 200,
    'get analytics has data': (r) => r.json('totalEvents') !== undefined,
  }) || errorRate.add(1);

  sleep(2);

  // Test 4: Update user profile
  res = http.put(`${BASE_URL}/users/123`, JSON.stringify({
    firstName: 'Updated',
    lastName: 'User'
  }), { headers });

  check(res, {
    'update user status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(1);
}

export function teardown(data) {
  // Cleanup
  console.log('Load test completed');
}
