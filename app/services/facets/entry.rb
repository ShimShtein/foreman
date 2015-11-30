module Facets
  class Entry
    attr_accessor :name, :model, :helper, :extension,
      :api_single_view, :api_list_view,
      :api_param_group_description, :api_param_group, :api_controller,
      :tabs,
      :compatibility_properties

    @compatibility_properties = []

    def initialize(facet_model, facet_name)
      raise ArgumentError, "facet_model must be a class" unless facet_model.is_a? Class

      facet_name ||= to_name(facet_model)
      raise ArgumentError, "facet_name must be a symbol" unless facet_name.is_a? Symbol

      self.model = facet_model
      self.name = facet_name
    end

    def add_helper(facet_helper)
      raise ArgumentError, "facet_helper must be a module" unless facet_helper.is_a? Module
      self.helper = facet_helper
    end

    def add_tabs(tabs)
      raise ArgumentError, 'tabs should be a hash or a helper method symbol' unless tabs.is_a?(Hash) || tabs.is_a?(Symbol)
      self.tabs = tabs
    end

    def extend_model(extension_class)
      raise ArgumentError, "extension_class must be a module" unless extension_class.is_a? Module
      self.extension = extension_class
    end

    def api_view(view_templates)
      raise ArgumentError, "view_templates must be a hash" unless view_templates.is_a? Hash
      #options can be either string or nil
      raise ArgumentError, "view_templates[:single] must be a String" unless (view_templates[:single] || '').is_a? String
      raise ArgumentError, "view_templates[:list] must be a String" unless (view_templates[:list] || '').is_a? String

      self.api_single_view = view_templates[:single]
      self.api_list_view = view_templates[:list]
    end

    def api_docs(param_group, controller, description = nil)
      raise ArgumentError, "param_group must be a symbol" unless param_group.is_a? Symbol
      raise ArgumentError, "controller must be a class" unless controller.is_a? Class
      raise ArgumentError, "description must be a string" unless (description || '').is_a? String

      self.api_param_group = param_group
      self.api_controller = controller
      self.api_param_group_description = description
    end

    def template_compatibility_properties(*property_symbols)
      raise ArgumentError, "all properties must be symbols" if property_symbols.any? { |p| !p.is_a? Symbol }
      self.compatibility_properties = property_symbols
    end

    private

    def to_name(facet_model)
      facet_model.name.demodulize.underscore.to_sym
    end
  end
end
