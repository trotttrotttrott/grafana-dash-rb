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

class Cassandra

  include GrafanaDash

  def generate(environment, datacenters)

    cassandra = Dashboard.new title: "Cassandra (#{environment.split('-').last})"

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
    cassandra.add_templating templating.properties

    # Cache

    cache_row = Row.new title: 'Cache'

    %w(
      ChunkCache
      CounterCache
      KeyCache
      RowCache
    ).each do |cache_type|
      cache_graph = Graph.new title: cache_type, span: 3
      datacenters.each do |datacenter|
        cache_graph.add_target(
          datasource: datacenter,
          expr: "cassandra_cache_size{instance=~'.+-$cluster-.+', cache='#{cache_type}'}",
          legendFormat: '{{instance}}'
        )
      end
      cache_row.add_panel cache_graph.properties
    end
    cassandra.add_row cache_row.properties

    # Clients

    client_row = Row.new title: 'Clients'

    %w(
      authfailure
      authsuccess
      connectednativeclients
      connectedthriftclients
    ).each do |metric|
      client_graph = Graph.new(
        span: 3,
        title: metric,
        yaxes: [
          { format: 'short' },
          { show: false }
        ]
      )
      datacenters.each do |datacenter|
        client_graph.add_target(
          datasource: datacenter,
          expr: "cassandra_client_#{metric}{instance=~'.+-$cluster-.+'}",
          legendFormat: '{{instance}}'
        )
      end
      client_row.add_panel client_graph.properties
    end
    cassandra.add_row client_row.properties

    # Client Requests

    requests_row = Row.new title: 'Client Requests'

    %w(
      latency
      viewwritelatency
    ).each do |metric|
      requests_graph = Graph.new(
        span: 3,
        title: metric,
        yaxes: [
          { format: 'µs' },
          { show: false }
        ]
      )
      datacenters.each do |datacenter|
        requests_graph.add_target(
          datasource: datacenter,
          expr: "cassandra_clientrequest_#{metric}{instance=~'.+-$cluster-.+'}",
          legendFormat: '{{instance}} - {{clientrequest}}'
        )
      end
      requests_row.add_panel requests_graph.properties
    end

    requests_graph = Graph.new(
      span: 3,
      title: 'viewreplicassuccess %',
      yaxes: [
        { format: 'percent', min: 0, max: 100 },
        { show: false }
      ]
    )
    expr =  "cassandra_clientrequest_viewreplicasattempted{instance=~'.+-$cluster-.+'}"
    expr << " / cassandra_clientrequest_viewreplicassuccess{instance=~'.+-$cluster-.+'}"
    expr << " * 100"
    datacenters.each do |datacenter|
      requests_graph.add_target(
        datasource: datacenter,
        expr: expr,
        legendFormat: '{{instance}}'
      )
    end
    requests_row.add_panel requests_graph.properties

    requests_graph = Graph.new(
      span: 3,
      title: 'viewreplicasattempted count',
      yaxes: [
        { format: 'short' },
        { show: false }
      ]
    )
    datacenters.each do |datacenter|
      requests_graph.add_target(
        datasource: datacenter,
        expr: "cassandra_clientrequest_viewreplicasattempted{instance=~'.+-$cluster-.+'}",
        legendFormat: '{{instance}}'
      )
    end
    requests_row.add_panel requests_graph.properties

    %w(
      conditionnotmet
      failures
      timeouts
      unavailables
      unfinishedcommit
      viewpendingmutations
    ).each do |metric|
      requests_graph = Graph.new(
        span: 4,
        title: metric,
        yaxes: [
          { format: 'short' },
          { show: false }
        ]
      )
      datacenters.each do |datacenter|
        requests_graph.add_target(
          datasource: datacenter,
          expr: "cassandra_clientrequest_#{metric}{instance=~'.+-$cluster-.+'}",
          legendFormat: '{{instance}} - {{clientrequest}}'
        )
      end
      requests_row.add_panel requests_graph.properties
    end

    cassandra.add_row requests_row.properties

    cassandra.properties.to_json
  end
end
