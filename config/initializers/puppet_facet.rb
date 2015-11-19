Rails.application.config.to_prepare do
  Facets.register(PuppetFacet) do
    extend_model PuppetHostExtensions
    add_helper PuppetFacetHelper
    add_tabs :puppet_tabs
    api_view :list => 'api/v2/puppet_facets/base', :single => 'api/v2/puppet_facets/single_host_view'
    template_compatibility_properties :environment_id, :puppet_proxy_id, :puppet_ca_proxy_id
  end
end
