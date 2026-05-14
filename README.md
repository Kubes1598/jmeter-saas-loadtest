# jmeter-saas-loadtest

A JMeter test plan I built when I was load-testing the Salesgroup.ai staging environment. Marketing was about to launch a campaign that we expected would 5x daily signups, and nobody could say with confidence whether the API would hold up. So I built this.

It ramps from 100 to 500 concurrent users in steps over 12 minutes, hitting the real auth → checkout → webhook path. Two bottlenecks turned up before we ever sent the marketing email: a DB connection pool that maxed out around 280 users, and a Stripe webhook handler that started backing up under load.

## What it does

- Models the journey: login → OAuth callback → plan select → checkout init → webhook poll.
- Stepped ramp: 100 → 200 → 300 → 500 over 12 minutes, with 5 minutes of steady state at each step. Steps make it easy to spot the exact user count where things break.
- Reads credentials from `users.csv` so the auth cache doesn't quietly cheat the test.
- HTTP status assertions, JSON Path assertions for business invariants, and a Duration Assertion for the 800ms p95 SLO.
- Writes to `results/run.jtl` and generates an HTML report you can share with non-engineers.

## Running it

```bash
./run.sh staging.example.com 500 800
```

Arguments: host, max concurrent users, p95 budget in ms. The defaults work; override if needed.

Or click "Actions → Load test (manual) → Run workflow" on GitHub and pass the host and user count. The workflow uploads the HTML report as a build artifact.

## Parameters you can tweak

| Property      | Default                  | What it does                              |
| ------------- | ------------------------ | ----------------------------------------- |
| `host`        | `staging.example.com`    | Target host (no scheme).                  |
| `users`       | `500`                    | Final concurrent user count.              |
| `ramp_time`   | `720` (s)                | Time to ramp up to `users`.               |
| `duration`    | `2400` (s)               | Total test duration.                      |
| `p95_budget`  | `800` (ms)               | Duration Assertion fails above this.      |

## Things I learned the hard way

A few lessons from running this against real environments.

Always read credentials from a CSV. The first time I ran something like this I used one test account for all 500 threads, and the auth cache made everything look great. Real users don't share a cookie. Use a credential pool the size of your thread count or you're measuring the wrong thing.

Stepped ramps beat linear ramps. With a linear ramp you can see "it broke somewhere between 0 and 500". With steps you can see "it started failing at user 280, recovered when the DB pool resized, and broke again at 420." The diagnostic value of holding load steady is a lot higher than people give it credit for.

Pair the client metrics with server metrics. JMeter will tell you "p95 jumped to 2.1 seconds." Prometheus on the server will tell you "DB pool was saturated for 90 seconds." You need both stories to know what to fix.

## Related

- The companion API-only test suite I built later: [k6-api-stress](https://github.com/Kubes1598/k6-api-stress).
- Portfolio case study: [ajimati-portfolio](https://github.com/Kubes1598/ajimati-portfolio).

## License

MIT. See [LICENSE](./LICENSE).
