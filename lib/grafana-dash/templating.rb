module GrafanaDash
  class Templating

    attr_reader :properties

    def initialize(options = {})
      {
        list: []
      }.each do |k, v|
        options[k] ||= v
      end
      @properties = options
    end

    def add_variable(variable)
      variable[:current] ||= variable[:options].first if variable[:options]
      properties[:list] << variable
    end
  end
end
