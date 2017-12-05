module GrafanaDash
  class Dashboard

    attr_reader :properties

    def initialize(options = {})
      {
        panels: [],
        rows: [],
        templating: {},
        time: {
          from: 'now-1h',
          to: 'now'
        }
      }.each do |k, v|
        options[k] ||= v
      end
      @properties = options
    end

    def add_panel(panel)
      properties[:panels] << panel
    end

    def add_row(row)
      properties[:rows] << row
    end

    def add_templating(templating)
      properties[:templating] = templating
    end
  end
end
