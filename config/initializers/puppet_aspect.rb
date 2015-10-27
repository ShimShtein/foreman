Rails.application.config.to_prepare do
  HostAspects.configuration.register(:puppet_aspect) do
    extend_model :puppet_host_extensions
    add_helper :puppet_aspect_helper
    add_tabs :puppet_tabs
  end
end
