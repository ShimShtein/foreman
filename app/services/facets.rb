module Facets
  module_function

  def registered_facets
    configuration.dup
  end

  def register(facet_model, facet_name = nil, &block)
    entry = Facets::Entry.new(facet_model, facet_name)

    entry.instance_eval(&block) if block_given?

    configuration[entry.name] = entry

    Facets::ManagedHostExtensions.register_facet_relation(Host::Managed, entry)
  end

  #declare private module methods.
  class << self
    private

    def configuration
      @configuration ||= {}
    end
  end
end
