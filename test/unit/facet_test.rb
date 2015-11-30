require 'test_helper'
require 'facet_test_helper'

class TestFacet < HostFacetBase
end

module TestModule
  class ModuleTestFacet < HostFacetBase
  end
end

class FacetTest < ActiveSupport::TestCase
  setup do
    @config = {}
    Facets.stubs(:configuration).returns(@config)
  end

  teardown do
    Host::Managed.cloned_parameters[:include].delete(:test_model)
    Host::Managed.cloned_parameters[:include].delete(:test_facet)
    Host::Managed.cloned_parameters[:include].delete(:namespaced_facet)
  end

  context 'namespaced facets' do
    setup do
      Facets.register TestModule::ModuleTestFacet, :namespaced_facet

      @host = Host::Managed.new
      @facet = @host.build_namespaced_facet
    end

    test 'can create a namespaced facet' do
      assert_equal @facet, @host.facets.first
    end

    test 'returns facets attributes' do
      attributes = @host.attributes

      assert_not_nil attributes["namespaced_facet_attributes"]
    end
  end

  context 'managed host behavior' do
    setup do
      Facets.register TestFacet do
        template_compatibility_properties :test_property
      end

      @host = Host::Managed.new
      @facet = @host.build_test_facet
    end

    test 'registered facets are subscribed properly' do
      assert_equal @facet, @host.facets.first
    end

    test 'facets are queried for info' do
      @facet.expects(:info).returns({:my_fact => :my_value})
      info = @host.info

      assert_equal :my_value, info[:my_fact]
    end

    test 'facets are notified for facts import' do
      @facet.class.expects(:populate_fields_from_facts)
      @host.stubs(:save)

      @host.populate_fields_from_facts(:domain => 'example.com',
                                       :operatingsystem => 'RedHat',
                                       :operatingsystemrelease => '6.2',
                                       :macaddress_eth0 => '00:00:11:22:11:22',
                                       :ipaddress_eth0 => '192.168.0.1',
                                       :interfaces => 'eth0')
    end

    test 'facets are cloned to the new host' do
      facet_clone = @facet.dup
      @facet.stubs(:dup).returns(facet_clone)

      cloned_host = @host.clone

      assert_equal facet_clone, cloned_host.test_facet
      assert_equal facet_clone, cloned_host.facets.first
    end

    test 'facets can modify templates selection' do
      @facet.expects(:template_filter_options).at_least_once.returns({:my_attribute => :my_value})
      ProvisioningTemplate.expects(:find_template).at_least_once.with { |params| params[:my_attribute] == :my_value }.returns([])

      @host.available_template_kinds
    end

    test 'facets are included in attributes' do
      attributes = @host.attributes

      assert_not_nil attributes["test_facet_attributes"]
    end

    test 'host redirects compatibility properties to facet' do
      @facet.expects(:test_property).returns('my value')

      assert_equal 'my value', @host.test_property
    end
  end
end
