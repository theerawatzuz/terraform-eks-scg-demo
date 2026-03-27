import http from "k6/http";
import { check, sleep } from "k6";

// Test to trigger WeatherMapHighCPU alert
// Alert threshold: CPU > 80% of limit for 5 minutes

export const options = {
  stages: [
    { duration: "30s", target: 50 }, // Ramp up to 50 VUs
    { duration: "7m", target: 50 }, // Stay at 50 VUs for 7 minutes (enough to trigger 5min alert)
    { duration: "30s", target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<2000"], // 95% of requests should be below 2s
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3001";

export default function () {
  // Mix of endpoints to generate CPU load
  const cities = ["Bangkok", "London", "Tokyo", "New York", "Paris", "Sydney"];
  const city = cities[Math.floor(Math.random() * cities.length)];

  const res = http.get(`${BASE_URL}/api/weather?city=${city}`);

  check(res, {
    "status is 200": (r) => r.status === 200,
  });

  // Small sleep to maintain sustained load
  sleep(0.1);
}

export function handleSummary(data) {
  return {
    stdout: JSON.stringify(
      {
        test: "high-cpu",
        alert: "WeatherMapHighCPU",
        threshold: "CPU > 80% for 5 minutes",
        requests: data.metrics.http_reqs.values.count,
        duration: data.metrics.iteration_duration.values.avg,
        errors: data.metrics.http_req_failed.values.passes || 0,
      },
      null,
      2,
    ),
  };
}
