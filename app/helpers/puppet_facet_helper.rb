module PuppetFacetHelper
  def self.included(base)
    base.class_eval do
      alias_method_chain :host_title_actions, :puppet
      alias_method_chain :overview_fields, :puppet
    end
  end

  def host_title_actions_with_puppet(host)
    title_actions(
      button_group(link_to_if_authorized(_("Run puppet"), hash_for_puppetrun_host_path(:id => host).merge(:auth_object => host, :permission => 'puppetrun_hosts'),
                              :disabled => !Setting[:puppetrun],
                              :title    => _("Trigger a puppetrun on a node; requires that puppet run is enabled"))
                             )) if host.puppet_facet.try(:puppet_proxy)
    host_title_actions_without_puppet(host)
  end

  def overview_fields_with_puppet(host)
    base = overview_fields_without_puppet(host)
    base << [_("Puppet Environment"), (link_to(host.puppet_facet.environment, hosts_path(:search => "environment = #{host.puppet_facet.environment}")) if host.puppet_facet and host.puppet_facet.environment)]
    base
  end

  def puppet_tabs(host)
    base = {}

    if SmartProxy.with_features("Puppet").count > 0
      base[:puppetclasses] = 'puppet_facets/puppetclasses_tab'
    end

    base
  end
end
