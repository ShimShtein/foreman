attributes :environment_id, :environment_name, :puppet_ca_proxy_id, :puppet_proxy_id

# to avoid deprecation warning on puppet_status method
attributes :configuration_status => :puppet_status
