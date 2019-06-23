# Dashboard for displaying metrics regarding Cassandra anti-entropy repair. The metrics
# this was originally tested with were output from Carousul as files and collected via
# the Prometheus Node Exporter Textfile Collector.
#
# * https://github.com/trotttrotttrott/carousul
# * https://github.com/prometheus/node_exporter

require_relative '../lib/grafana-dash'

class CassandraRepair

  include GrafanaDash

  def generate(environment, datacenters, keyspaces)

    cassandra = Dashboard.new title: "Cassandra Anti-entropy Repair (#{environment.split('-').last})"

    # Each keyspace has a row

    keyspaces.each do |keyspace|

      row = Row.new title: keyspace

      # Success

      success_graph = Graph.new(
        legend: { show: false, hideZero: false },
        span: 12,
        title: 'success',
        yaxes: [{ format: 'short' }, { show: false }]
      )
      datacenters.each do |datacenter|
        success_graph.add_target(
          datasource: datacenter,
          expr: "cassandra_repair_success_#{keyspace}",
          legendFormat: '{{instance}}'
        )
      end
      row.add_panel success_graph.properties

      # Duration

      %w(
        lock
        repair
        total
      ).each do |metric|
        duration_graph = Graph.new(
          span: 4,
          title: metric,
          yaxes: [{ format: 'ms' }, { show: false }]
        )
        datacenters.each do |datacenter|
          duration_graph.add_target(
            datasource: datacenter,
            expr: "cassandra_repair_duration_#{metric}_milliseconds_#{keyspace}",
            legendFormat: '{{instance}}'
          )
        end
        row.add_panel duration_graph.properties
      end

      cassandra.add_row row.properties
    end

    cassandra.properties.to_json
  end
end
