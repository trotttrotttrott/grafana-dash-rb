module GrafanaDash
  class Graph

    attr_reader :properties

    def initialize(options = {})
      {
        datasource: '-- Mixed --',
        legend: { show: false, hideZero: true },
        tooltip: { shared: true },
        targets: [],
        type: 'graph',
        xaxis: { mode: 'time' },
        yaxes: [
          { format: 'decbytes' },
          { show: false }
        ]
      }.each do |k, v|
        options[k] ||= v
      end
      @properties = options
    end

    def add_target(target)
      properties[:targets] << target
    end
  end
end
