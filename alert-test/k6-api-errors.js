import http from "k6/http";
import { check, sleep } from "k6";

// Test to trigger WeatherAPIHighErrorRate alert
// Alert threshold: Weather API error rate > 10% for 2 minutes

export const options = {
  stages: [
    { duration: "10s", target: 15 }, // Ramp up
    { duration: "3m", target: 15 }, // Stay for 3 minutes
    { duration: "10s", target: 0 }, // Ramp down
  ],
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3001";

export default function () {
  // Mix of valid and invalid city names
  // Invalid cities should trigger Weather API errors
  const cities = [
    // Valid cities (70%)
    "Bangkok",
    "London",
    "Tokyo",
    "Paris",
    "Sydney",
    "Berlin",
    "Moscow",

    // Invalid cities to trigger API errors (30%)
    "InvalidCity123",
    "XYZ",
    "!!!",
    "NotACity",
    "ErrorTest",
  ];

  const city = cities[Math.floor(Math.random() * cities.length)];
  const res = http.get(`${BASE_URL}/api/weather?city=${city}`);

  check(res, {
    "request completed": (r) => r.status !== 0,
  });

  sleep(0.3);
}

export function handleSummary(data) {
  return {
    stdout: JSON.stringify(
      {
        test: "api-errors",
        alert: "WeatherAPIHighErrorRate",
        threshold: "Weather API error rate > 10% for 2 minutes",
        requests: data.metrics.http_reqs.values.count,
        errors: data.metrics.http_req_failed.values.passes || 0,
        error_rate:
          (
            ((data.metrics.http_req_failed.values.passes || 0) /
              data.metrics.http_reqs.values.count) *
            100
          ).toFixed(2) + "%",
      },
      null,
      2,
    ),
  };
}
