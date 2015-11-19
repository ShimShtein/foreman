module Classification
  class PuppetParam < Base
    delegate :environment_id, :puppetclass_ids, :classes,
             :to => :puppet_facet
    delegate :environment, :puppetclass,
             :to => :puppet_facet

    def initialize(args = {})
      super

      @puppet_facet = @host.puppet_facet if @host && @host.respond_to?(:puppet_facet)
    end

    protected

    attr_reader :puppet_facet
  end
end
