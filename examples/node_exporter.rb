# Dashboard for displaying a handful of Prometheus Node Exporter metrics.
#
# * https://github.com/prometheus/node_exporter
#
# Something to note is that the `instance_type` variable is used in regexes to
# filter metrics by "instance" labels associated with metrics.

require_relative '../lib/grafana-dash'

class NodeExporter

  include GrafanaDash

  def generate(environment, datacenters)

    dashboard = Dashboard.new title: "Node Exporter (#{environment.split('-').last})"

    # Templating

    templating = Templating.new
    instance_type_options = %w(
      cassandra
      consul-server
      nomad-server
      nomad-client
      bastion
      prometheus
      vault
    )
    templating.add_variable(
      allValue: '.',
      current: { text: 'All', value: '$__all' },
      includeAll: true,
      name: 'instance_type',
      options: [{ selected: true, text: 'All', value: '$__all'}].concat(instance_type_options.map do |type|
        { text: type, value: type }
      end),
      query: instance_type_options.join(','),
      type: 'custom'
    )
    dashboard.add_templating templating.properties

    # CPU

    cpu_row = Row.new title: 'CPU'
    cpu_utilization_graph = Graph.new(
      span: 6,
      title: 'CPU Utilization',
      yaxes: [
        { format: 'percent' },
        { show: false }
      ]
    )
    load_graph = Graph.new(
      span: 6,
      title: 'Load',
      yaxes: [
        { format: 'percent' },
        { show: false }
      ]
    )
    datacenters.each do |datacenter|
      cpu_utilization_graph.add_target(
        datasource: datacenter,
        expr: '100 - (avg by (instance, cpu) (irate(node_cpu{mode="idle", instance=~".+$instance_type.+"}[5m])) * 100)',
        legendFormat: '{{instance}} - {{cpu}}'
      )
      %w(1 5 15).each do |interval|
        load_graph.add_target(
          datasource: datacenter,
          expr: "(avg by (instance) (node_load#{interval}{instance=~'.+$instance_type.+'})) / (count by (instance) (node_cpu{mode='system', instance=~'.+$instance_type.+'})) * 100",
          legendFormat: "{{instance}} - {{load#{interval}}}"
        )
      end
    end
    cpu_row.add_panel cpu_utilization_graph.properties
    cpu_row.add_panel load_graph.properties
    dashboard.add_row cpu_row.properties

    # Memory

    memory_row = Row.new title: 'Memory'
    active_memory_graph = Graph.new(
      legend: {
        alignAsTable: true,
        avg: true,
        current: true,
        hideZero: true,
        max: true,
        min: false,
        rightSide: true,
        show: true,
        total: false,
        values: true
      },
      seriesOverrides: [
        { alias: '/.+ bytes/', yaxis: 2 }
      ],
      span: 12,
      title: 'Active Memory',
      yaxes: [
        { format: 'percent' },
        { format: 'bytes' }
      ]
    )
    datacenters.each do |datacenter|
      active_memory_graph.add_target(
        datasource: datacenter,
        expr: "node_memory_Active{instance=~'.+$instance_type.+'} / node_memory_MemTotal{instance=~'.+$instance_type.+'} * 100",
        legendFormat: '{{instance}}'
      )
      active_memory_graph.add_target(
        datasource: datacenter,
        expr: "node_memory_Active{instance=~'.+$instance_type.+'}",
        legendFormat: '{{instance}} bytes'
      )
    end
    memory_row.add_panel active_memory_graph.properties
    dashboard.add_row memory_row.properties

    # Filesystem

    filesystem_row = Row.new title: 'Filesystem'
    filesystem_free_graph = Graph.new(
      legend: {
        alignAsTable: true,
        avg: false,
        current: true,
        hideZero: true,
        max: false,
        min: false,
        rightSide: true,
        show: true,
        total: false,
        values: true
      },
      seriesOverrides: [
        { alias: '/.+ bytes/', yaxis: 2 }
      ],
      span: 12,
      title: 'Filesystem Used',
      yaxes: [
        { format: 'percent' },
        { format: 'bytes' }
      ]
    )
    datacenters.each do |datacenter|
      filesystem_free_graph.add_target(
        datasource: datacenter,
        expr: "100 - (node_filesystem_free{instance=~'.+$instance_type.+', mountpoint !~ '^/(mnt|run|etc)(.+)?'} / node_filesystem_size{instance=~'.+$instance_type.+', mountpoint !~ '^/(mnt|run|etc)(.+)?'} * 100)",
        legendFormat: '{{instance}} - {{mountpoint}}'
      )
      filesystem_free_graph.add_target(
        datasource: datacenter,
        expr: "node_filesystem_size{instance=~'.+$instance_type.+', mountpoint !~ '^/(mnt|run|etc)(.+)?'} - node_filesystem_free{instance=~'.+$instance_type.+', mountpoint !~ '^/(mnt|run|etc)(.+)?'}",
        legendFormat: '{{instance}} - {{mountpoint}} bytes'
      )
    end
    filesystem_row.add_panel filesystem_free_graph.properties
    dashboard.add_row filesystem_row.properties

    dashboard.properties.to_json
  end
end
