# Dashboard for displaying various series collected by the Prometheus JMX exporter.
#
# https://github.com/prometheus/jmx_exporter
#
# The metrics this was originally tested with was collected by Prometheus JMX Exporter
# version 0.10. The exporter was configured with the following:
#
# lowercaseOutputLabelNames: true
# lowercaseOutputName: true
# rules:
# - pattern: org.apache.cassandra.metrics<type=(Connection|Streaming), scope=(\S*), name=(\S*)><>(Count|Value)
#   name: cassandra_$1_$3
#   labels:
#     address: "$2"
# - pattern: org.apache.cassandra.metrics<type=(\S*)(?:, ((?!scope)\S*)=(\S*))?(?:, scope=(\S*))?,
#     name=(\S*)><>(Count|Value)
#   name: cassandra_$1_$5
#   labels:
#     "$1": "$4"
#     "$2": "$3"

require_relative '../lib/grafana-dash'

class CassandraVerbose

  include GrafanaDash

  def generate(environment, datacenters)

    cassandra = Dashboard.new title: "Cassandra Verbose (#{environment.split('-').last})"

    metric_groups = %w(
      bufferpool
      cache
      client
      clientrequest
      columnfamily
      commitlog
      compaction
      connection
      cql
      droppedmessage
      index
      keyspace
      memtablepool
      messaging
      readrepair
      storage
      streaming
      table
      threadpools
    )

    # Templating

    templating = Templating.new
    templating.add_variable(
      name: 'cluster',
      options: [
        { text: 'iam', value: 'iam' },
        { text: 'iot', value: 'iot' }
      ],
      type: 'custom'
    )

    # README

    row = Row.new title: 'README', height: 0
    readme_content = <<-EOS
Graphs all Cassandra metrics we are collecting grouped by concern.
The groups are separated by collapsed rows so that each can be loaded/displayed individually.

The purpose of this is to provide a visual overview of all Cassandra metrics available.
It is to help us learn about the metrics we're collecting and facilitate the creation of more specialized dashboards.
EOS
    row.add_panel Graph.new(
      content: readme_content,
      height: 0,
      span: 12,
      type: 'text'
    ).properties

    cassandra.add_row row.properties

    # Metrics

    metric_groups.each do |metric_group|

      templating.add_variable(
        current: { text: 'All', value: '$__all' },
        datasource: datacenters.first,
        includeAll: true,
        multi: true,
        name: metric_group,
        query: "metrics(cassandra_#{metric_group}_.+)",
        refresh: 1,
        type: 'query'
      )

      row = Row.new title: metric_group

      graph = Graph.new(
        title: "$#{metric_group}",
        repeat: metric_group,
        yaxes: [
          { format: 'short' },
          { show: false }
        ]
      )

      datacenters.each do |datacenter|
        graph.add_target(
          datasource: datacenter,
          expr: "$#{metric_group}{instance=~'.+-$cluster-.+'}"
        )
      end

      row.add_panel graph.properties

      cassandra.add_row row.properties
    end

    cassandra.add_templating templating.properties

    cassandra.properties.to_json
  end
end
