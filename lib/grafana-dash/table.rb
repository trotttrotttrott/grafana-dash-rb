module GrafanaDash
  class Table

    attr_reader :properties

    def initialize(options = {})
      {
        datasource: '-- Mixed --',
        styles: [],
        targets: [],
        type: 'table'
      }.each do |k, v|
        options[k] ||= v
      end
      @properties = options
    end

    def add_style(style)
      properties[:styles] << style
    end

    def add_target(target)
      properties[:targets] << target
    end
  end
end
