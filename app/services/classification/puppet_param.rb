module Classification
  class PuppetParam < Base
    delegate :environment_id, :puppetclass_ids, :classes,
             :to => :puppet_aspect
    delegate :environment, :puppetclass,
             :to => :puppet_aspect

    def initialize(args = {})
      super

      @puppet_aspect = @host.puppet_aspect if @host && @host.respond_to?(:puppet_aspect)
    end

    protected

    attr_reader :puppet_aspect
  end
end
