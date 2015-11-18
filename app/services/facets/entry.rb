module Facets
  class Entry
    ATTRIBUTES = [:name, :model, :helper, :extension, :api_controller]
    attr_accessor(*ATTRIBUTES)
    attr_accessor :api_single_view, :api_list_view, :tabs, :api_param_group, :api_param_group_description

    ATTRIBUTES.each do |attr|
      define_method "#{attr}_class".to_sym do
        sym = self.send(attr)
        to_class(sym)
      end
    end

    def initialize(facet_name, facet_model)
      self.name = to_name(facet_name)
      self.model = to_model(facet_model)
    end

    def add_helper(facet_helper)
      self.helper = facet_helper.try(:to_sym)
    end

    def add_tabs(tabs)
      raise ArgumentError, 'tabs should be a hash or a helper method symbol' unless tabs.is_a?(Hash) || tabs.is_a?(Symbol)
      self.tabs = tabs
    end

    def extend_model(extension_symbol)
      self.extension = to_symbol(extension_symbol)
    end

    def api_view(list_view_template = nil, single_item_template = nil)
      self.api_single_view = single_item_template if single_item_template
      self.api_list_view = list_view_template if list_view_template
    end

    def api_pie(param_group, controller, description = nil)
      self.api_param_group = param_group
      self.api_controller = controller
      self.api_param_group_description = description
    end

    private

    def to_name(facet_name)
      to_symbol(facet_name)
    end

    def to_model(facet_model)
      to_symbol(facet_model) || self.name
    end

    def to_class(symbol)
      symbol.to_s.camelize.constantize if symbol
    end

    def to_symbol(input)
      return nil unless input
      input = input.name if input.is_a? Class
      input.to_s.underscore.to_sym
    end
  end
end
