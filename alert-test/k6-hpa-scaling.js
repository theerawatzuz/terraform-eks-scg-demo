import http from "k6/http";
import { check, sleep } from "k6";

// Test to trigger WeatherMapHPAScaling and WeatherMapHPAMaxReplicas alerts
// HPA should scale based on CPU/Memory metrics

export const options = {
  stages: [
    { duration: "30s", target: 100 }, // Rapid ramp up to trigger HPA
    { duration: "5m", target: 100 }, // Sustained load to reach max replicas
    { duration: "1m", target: 50 }, // Reduce load
    { duration: "30s", target: 0 }, // Ramp down to trigger scale down
  ],
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3001";

export default function () {
  const cities = ["Bangkok", "London", "Tokyo", "New York", "Paris"];
  const city = cities[Math.floor(Math.random() * cities.length)];

  const res = http.get(`${BASE_URL}/api/weather?city=${city}`);

  check(res, {
    "status is 200": (r) => r.status === 200,
  });

  // Very short sleep to maximize load
  sleep(0.05);
}

export function handleSummary(data) {
  return {
    stdout: JSON.stringify(
      {
        test: "hpa-scaling",
        alerts: ["WeatherMapHPAScaling", "WeatherMapHPAMaxReplicas"],
        threshold: "HPA replica count changes / reaches max",
        requests: data.metrics.http_reqs.values.count,
        rps: (
          data.metrics.http_reqs.values.count /
          (data.state.testRunDurationMs / 1000)
        ).toFixed(2),
        errors: data.metrics.http_req_failed.values.passes || 0,
      },
      null,
      2,
    ),
  };
}
