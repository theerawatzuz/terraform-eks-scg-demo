import http from "k6/http";
import { check, sleep } from "k6";

// Test to trigger WeatherMapHigh5xxRate alert
// Alert threshold: 5xx rate > 0.05 req/s for 2 minutes

export const options = {
  stages: [
    { duration: "10s", target: 10 }, // Ramp up
    { duration: "3m", target: 10 }, // Stay for 3 minutes (enough for 2min alert)
    { duration: "10s", target: 0 }, // Ramp down
  ],
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3001";

export default function () {
  // Mix of valid and invalid requests to generate errors
  const requests = [
    // Valid requests (20%)
    { url: `${BASE_URL}/api/weather?city=Bangkok`, shouldSucceed: true },
    { url: `${BASE_URL}/api/weather?city=London`, shouldSucceed: true },

    // Invalid endpoints to trigger 5xx or 404 (80%)
    { url: `${BASE_URL}/api/invalid-endpoint`, shouldSucceed: false },
    { url: `${BASE_URL}/api/crash`, shouldSucceed: false },
    { url: `${BASE_URL}/api/error`, shouldSucceed: false },
    { url: `${BASE_URL}/nonexistent`, shouldSucceed: false },
  ];

  const req = requests[Math.floor(Math.random() * requests.length)];
  const res = http.get(req.url);

  if (req.shouldSucceed) {
    check(res, {
      "valid request succeeded": (r) => r.status === 200,
    });
  } else {
    check(res, {
      "error request failed": (r) => r.status >= 400,
    });
  }

  sleep(0.5);
}

export function handleSummary(data) {
  return {
    stdout: JSON.stringify(
      {
        test: "http-errors",
        alert: "WeatherMapHigh5xxRate",
        threshold: "5xx rate > 0.05 req/s for 2 minutes",
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
