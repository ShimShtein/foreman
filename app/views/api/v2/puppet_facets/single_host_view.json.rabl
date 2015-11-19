node :puppetclasses do
  partial("api/v2/puppetclasses/base", :object => @host.puppetclasses)
end

node :all_puppetclasses do
  partial("api/v2/puppetclasses/base", :object => @host.all_puppetclasses)
end

node :puppet_facet do
  partial("api/v2/puppet_facets/base", :object => @host.puppet_facet)
end
