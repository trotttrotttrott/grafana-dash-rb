# Dashboard for displaying ALERTS series from a Prometheus data source in a table panel.

require_relative '../lib/grafana-dash'

class Alerts

  include GrafanaDash

  def generate(environment, datacenters)
    dashboard = Dashboard.new title: "Alerts (#{environment.split('-').last})"
    table = Table.new(title: 'Alerts', gridPos: { x: 0, y: 1, w: 24, h: 16 })
    table.add_style(alias: 'Time', pattern: 'Time', type: 'date')
    datacenters.each do |datacenter|
      table.add_target(datasource: datacenter, expr: 'ALERTS', format: 'table', instant: true)
    end
    dashboard.add_panel table.properties
    dashboard.properties.to_json
  end
end
