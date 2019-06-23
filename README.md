# Grafana Dash Rb

Ruby models of Grafana components.

**Warning:** only a small subset of Grafana dashboarding functionality is modeled. This is a PoC for writing dashboards as code with Ruby.

## Examples

There are a handful of [example dashboards](./examples/). These are the types of things that you'd write and maintain.

A simple way to try this out would be to run one of the examples with [pry](https://github.com/pry/pry) (or IRB). For example, the [tls.rb](./examples/tls.rb) example outputs dashboard JSON with just a table panel for displaying TLS certificate expiry info collected with the [Prometheus Blackbox Exporter](https://github.com/prometheus/blackbox_exporter).

```ruby
[1] pry(main)> require_relative 'examples/tls'
=> true
[2] pry(main)> dashboard = TLS.new
=> #<TLS:0x007f8484ab4888>
[3] pry(main)> dashboard.generate 'prod', %w(us-west us-central us-east)
=> "{\"title\":\"TLS (prod)\",\"panels\":[{\"title\":\"TLS Expiry\",\"gridPos\":{\"x\":0,\"y\":1,\"w\":24,\"h\":16},\"datasource\":\"-- Mixed --\",\"styles\":[{\"alias\":\"Cert Expiration\",\"pattern\":\"Value\",\"type\":\"date\"},{\"pattern\":\"Time\",\"type\":\"hidden\"},{\"pattern\":\"job\",\"type\":\"hidden\"}],\"targets\":[{\"datasource\":\"us-west\",\"expr\":\"1000 * probe_ssl_earliest_cert_expiry\",\"format\":\"table\",\"instant\":true,\"legendFormat\":\"{{ instance }}\"},{\"datasource\":\"us-central\",\"expr\":\"1000 * probe_ssl_earliest_cert_expiry\",\"format\":\"table\",\"instant\":true,\"legendFormat\":\"{{ instance }}\"},{\"datasource\":\"us-east\",\"expr\":\"1000 * probe_ssl_earliest_cert_expiry\",\"format\":\"table\",\"instant\":true,\"legendFormat\":\"{{ instance }}\"}],\"type\":\"table\"}],\"rows\":[],\"templating\":{},\"time\":{\"from\":\"now-1h\",\"to\":\"now\"}}"
```

These examples have a common pattern. Each contains a single class with a `generate` instance method that outputs a JSON string (a dashboard). The `generate` method also accepts two arguments - `environment` and `datacenters`. This is because all of these examples were writtlen for multiple Prometheus data sources across many datacenters.
