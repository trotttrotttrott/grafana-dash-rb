# Dashboard for displaying TLS expiry data in a table. This was originally tested
# with the Prometheus Blackbox Exporter 0.11.0.
#
# https://github.com/prometheus/blackbox_exporter

require_relative '../lib/grafana-dash'

class TLS

  include GrafanaDash

  def generate(environment, datacenters)
    dashboard = Dashboard.new title: "TLS (#{environment.split('-').last})"
    table = Table.new(title: 'TLS Expiry', gridPos: { x: 0, y: 1, w: 24, h: 16 })
    table.add_style(alias: 'Cert Expiration', pattern: 'Value', type: 'date')
    table.add_style(pattern: 'Time', type: 'hidden')
    table.add_style(pattern: 'job', type: 'hidden')
    datacenters.each do |datacenter|
      table.add_target(
        datasource: datacenter,
        expr: "1000 * probe_ssl_earliest_cert_expiry",
        format: 'table',
        instant: true,
        legendFormat: '{{ instance }}'
      )
    end
    dashboard.add_panel table.properties
    dashboard.properties.to_json
  end
end
