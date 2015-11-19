module Facets
  class Entry
    attr_reader :name, :model, :helper, :extension,
      :api_single_view, :api_list_view,
      :api_param_group_description, :api_param_group, :api_controller,
      :tabs,
      :compatibility_properties

    def initialize(facet_model, facet_name)
      @compatibility_properties = []
      raise ArgumentError, "facet_model must be a class" unless facet_model.is_a? Class

      facet_name ||= to_name(facet_model)
      raise ArgumentError, "facet_name must be a symbol" unless facet_name.is_a? Symbol

      @model = facet_model
      @name = facet_name
    end

    # Declare a helper module that will be added to host's view.
    def add_helper(facet_helper)
      raise ArgumentError, "facet_helper must be a module" unless facet_helper.is_a? Module
      @helper = facet_helper
    end

    # Declare additional tabs to host's single view.
    # The value can be either a static hash or a symbol for method specified in helper.
    # The hash should be in form:
    #   :tab_identifier => value_to_show_in_tab
    # later on, the framework will pass the value to +render+:
    #   render(val, :f => host_form)
    def add_tabs(tabs)
      raise ArgumentError, 'tabs should be a hash or a helper method symbol' unless tabs.is_a?(Hash) || tabs.is_a?(Symbol)
      @tabs = tabs
    end

    # Specify <tt>ActiveSupport::Concern</tt> to extend the host model
    def extend_model(extension_class)
      raise ArgumentError, "extension_class must be a module" unless extension_class.is_a? Module
      @extension = extension_class
    end

    # Specify changes to api view templates using this method
    # view_templates is a Hash with two keys:
    # [+:single+] the value is a path to +.rabl+ file that will be used in single host rabl template.
    # [+:list+] the value is a path to +.rabl+ file that will be used in hosts list rabl template.
    # each template is called in context of the host object:
    #   partial('value/from/the/hash', :object => @host)
    # Any +attributes+ statements will be added to the host object. It is advised to create a separate
    # node under the host, and put all the relevant values under it.
    # Examle for the template:
    #
    #   node :example_facet do
    #     partial("api/v2/example_facets/base", :object => @host.example_facet)
    #   end
    def api_view(view_templates)
      raise ArgumentError, "view_templates must be a hash" unless view_templates.is_a? Hash
      #options can be either string or nil
      raise ArgumentError, "view_templates[:single] must be a String" unless (view_templates[:single] || '').is_a? String
      raise ArgumentError, "view_templates[:list] must be a String" unless (view_templates[:list] || '').is_a? String

      @api_single_view = view_templates[:single]
      @api_list_view = view_templates[:list]
    end

    # Add API documentation extensions for describing host's create and update parameters.
    # We are using apipie's ability to specify external param_groups.
    # New Hash parameter is added to host with id in form of: "#{facet_name}_attributes",
    # The content of the node will be described by using param_group specified in +controller+
    # with id specified in +param_group+. There is also an option to specify custom description
    # for the whole "#{facet_name}_attributes"
    def api_docs(param_group, controller, description = nil)
      raise ArgumentError, "param_group must be a symbol" unless param_group.is_a? Symbol
      raise ArgumentError, "controller must be a class" unless controller.is_a? Class
      raise ArgumentError, "description must be a string" unless (description || '').is_a? String

      @api_param_group = param_group
      @api_controller = controller
      @api_param_group_description = description
    end

    # Use this method to maintain compatibility with older versions of foreman templates. Every property that
    # will be set here, will get a forwarder method in host, so the property will still be available for templates.
    # Example:
    # Let's say we have example_facet, that defines :foo property.
    # # Initialization:
    #  Facets.register(ExampleFacet) do
    #     template_compatibility_properties :foo
    #  end
    # ---
    # # Template:
    #  host.build_example_facet(:foo => 'bar')
    #  host.foo # => 'bar'
    def template_compatibility_properties(*property_symbols)
      raise ArgumentError, "all properties must be symbols" if property_symbols.any? { |p| !p.is_a? Symbol }
      @compatibility_properties = property_symbols
    end

    private

    def to_name(facet_model)
      facet_model.name.demodulize.underscore.to_sym
    end
  end
end
