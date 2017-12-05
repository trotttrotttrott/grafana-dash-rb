module GrafanaDash
  class Row

    attr_reader :properties

    def initialize(options = {})
      {
        collapse: true,
        panels: []
      }.each do |k, v|
        options[k] ||= v
      end
      @properties = options
    end

    def add_panel(panel)
      properties[:panels] << panel
    end
  end
end
