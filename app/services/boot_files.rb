class BootFiles
  class << self
    def providers
      (entries_from_plugins + local_entries).uniq
    end

    def register_boot_files_provider(provider)
      local_entries << provider
      provider
    end

    def entries_from_plugins
      Foreman::Plugin.all.map {|plugin| plugin.boot_files_providers}.compact.flatten
    end

    def local_entries
      @providers ||= []
    end
  end

  attr_reader :provider

  def initialize(entity)
    @provider = find_provider(entity)
  end

  private

  def find_provider(entity)
    provider_class = self.class.providers.first { |provider| provider.provides?(entity) }
    errors = ensure_provider(provider_class, entity)
    raise Foreman::Exception 'Could not find a provider for %{entity}. Providers returned %{errors}', { entity: entity, errors: errors } if errors.present?
    provider_class.new(entity)
  end

  def ensure_provider(selected_provider, entity)
    return if selected_provider.present?

    self.class.providers.reduce({}) do |errors_hash, provider|
      errors_hash[provider.friendly_name] = provider.errors(entity)
    end
  end
end
