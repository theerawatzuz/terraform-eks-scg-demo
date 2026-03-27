import http from "k6/http";
import { check, sleep } from "k6";

// Test to trigger WeatherMapHighMemory alert
// Alert threshold: Memory > 80% of limit for 5 minutes

export const options = {
  stages: [
    { duration: "1m", target: 30 }, // Ramp up to 30 VUs
    { duration: "7m", target: 30 }, // Stay at 30 VUs for 7 minutes
    { duration: "30s", target: 0 }, // Ramp down
  ],
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3001";

export default function () {
  // Generate requests that may accumulate memory
  const cities = [
    "Bangkok",
    "London",
    "Tokyo",
    "New York",
    "Paris",
    "Sydney",
    "Berlin",
    "Moscow",
    "Dubai",
    "Singapore",
    "Mumbai",
    "Seoul",
  ];

  // Make multiple requests in quick succession
  for (let i = 0; i < 5; i++) {
    const city = cities[Math.floor(Math.random() * cities.length)];
    const res = http.get(`${BASE_URL}/api/weather?city=${city}`);

    check(res, {
      "status is 200": (r) => r.status === 200,
    });
  }

  // Short sleep to maintain pressure
  sleep(0.5);
}

export function handleSummary(data) {
  return {
    stdout: JSON.stringify(
      {
        test: "high-memory",
        alert: "WeatherMapHighMemory",
        threshold: "Memory > 80% for 5 minutes",
        requests: data.metrics.http_reqs.values.count,
        duration: data.metrics.iteration_duration.values.avg,
        errors: data.metrics.http_req_failed.values.passes || 0,
      },
      null,
      2,
    ),
  };
}
