class PuppetAspect < HostAspectBase
  attr_accessible :environment_id, :host_id, :puppet_ca_proxy_id, :puppet_proxy_id, :puppet_status, :environment, :puppet_proxy, :puppet_ca

  belongs_to :puppet_proxy,    :class_name => "SmartProxy"
  belongs_to :puppet_ca_proxy, :class_name => "SmartProxy"
  belongs_to :environment, :counter_cache => :hosts_count

  before_save :check_puppet_ca_proxy_is_required?
  before_save :clear_puppetinfo, :if => :environment_id_changed?

  before_validation :set_hostgroup_defaults

  validates :environment_id,  :presence => true

  scoped_search :in => :puppet_proxy, :on => :name, :complete_value => true, :rename => :puppetmaster

  delegate :puppetclasses, :to => :host

  def after_clone
    self.puppet_status = 0
  end

  def template_filter_options(kind)
    { :environment_id => environment_id }
  end

  def puppetca?
    return false if host.respond_to?(:managed?) and !host.managed?
    !!(puppet_ca_proxy and puppet_ca_proxy.url.present?)
  end

  def puppetmaster
    puppet_proxy.to_s
  end

  def puppet_ca_server
    puppet_ca_proxy.to_s
  end

  #retuns fqdn of host puppetmaster
  def pm_fqdn
    puppetmaster == "puppet" ? "puppet.#{domain.name}" : "#{puppetmaster}"
  end

  # fall back to our puppet proxy in case our puppet ca is not defined/used.
  def check_puppet_ca_proxy_is_required?
    return true if puppet_ca_proxy_id.present? or puppet_proxy_id.blank?
    if puppet_proxy.has_feature?('Puppet CA')
      self.puppet_ca_proxy ||= puppet_proxy
    end
  rescue
    true # we don't want to break anything, so just skipping.
  end

  # Cleans Certificate and enable Autosign
  # Called before a host is given their provisioning template
  # Returns : Boolean status of the operation
  def handle_ca
    # If there's no puppetca, tell the caller that everything is ok
    return true unless Setting[:manage_puppetca]
    return true unless puppetca?

    # From here out, we expect things to work and return true
    return false unless host.respond_to?(:initialize_puppetca, true)
    return false unless host.initialize_puppetca
    return false unless host.delCertificate

    # If use_uuid_for_certificates is true, reuse the certname UUID value.
    # If false, then reset the certname if it does not match the hostname.
    if (Setting[:use_uuid_for_certificates] ? !Foreman.is_uuid?(host.certname) : host.certname != host.hostname)
      logger.info "Removing certificate value #{host.certname} for host #{host.name}"
      host.certname = nil
    end

    host.setAutosign
  end

  def set_hostgroup_defaults
    return unless host.try(:hostgroup)
    assign_hostgroup_attributes(%w{environment_id})

    assign_hostgroup_attributes(["puppet_proxy_id"]) if host.new_record? || (!host.new_record? && !puppet_proxy_id.blank?)
    assign_hostgroup_attributes(["puppet_ca_proxy_id"]) if host.new_record? || (!host.new_record? && !puppet_ca_proxy_id.blank?)
  end

  def assign_hostgroup_attributes(attrs = [])
    attrs.each do |attr|
      next if send(attr).to_i == -1
      value = host.hostgroup.send("inherited_#{attr}")
      self.send("#{attr}=", value) unless send(attr).present?
    end
  end

  def puppetrun!
    unless puppet_proxy.present?
      errors.add(:base, _("no puppet proxy defined - cant continue"))
      logger.warn "unable to execute puppet run, no puppet proxies defined"
      return false
    end
    ProxyAPI::Puppet.new({:url => puppet_proxy.url}).run host.fqdn
  rescue => e
    errors.add(:base, _("failed to execute puppetrun: %s") % e)
    logger.warn "unable to execute puppet run: #{e}"
    logger.debug e.backtrace.join("\n")
    false
  end

  def smart_proxy_ids
    [puppet_proxy_id, puppet_ca_proxy_id, host.hostgroup.try(:puppet_proxy_id), host.hostgroup.try(:puppet_ca_proxy_id)].uniq.compact
  end

  def set_non_empty_values(importer, methods)
    methods.each do |attr|
      value = importer.send(attr)
      self.send("#{attr}=", value) unless value.blank?
    end
  end

  def host_class_ids
    host.is_a?(Host::Base) ? host.host_classes.map { |c| c.puppetclass_id } : []
  end

  def all_puppetclass_ids
    cg_class_ids + hg_class_ids + host_class_ids
  end

  def classes(env = environment)
    conditions = {:id => all_puppetclass_ids }
    if env
      env.puppetclasses.where(conditions)
    else
      Puppetclass.where(conditions)
    end
  end

  alias_method :all_puppetclasses, :classes

  def puppetclass_ids
    classes.reorder('').pluck('puppetclasses.id')
  end

  def classes_in_groups
    conditions = {:id => cg_class_ids }
    if environment
      environment.puppetclasses.where(conditions) - parent_classes
    else
      Puppetclass.where(conditions) - parent_classes
    end
  end

  def individual_puppetclasses
    conditions = {:id => host_class_ids - cg_class_ids}
    if environment
      environment.puppetclasses.where(conditions)
    else
      Puppetclass.where(conditions)
    end
  end

  def available_puppetclasses
    return Puppetclass.scoped if environment_id.blank?
    environment.puppetclasses - parent_classes
  end

  def cg_class_ids
    cg_ids = host.config_group_ids + (host.hostgroup ? host.hostgroup.path.each.map(&:config_group_ids).flatten.uniq : [] )
    ConfigGroupClass.where(:config_group_id => cg_ids).pluck(:puppetclass_id)
  end

  def hg_class_ids
    hg_ids = host.hostgroup.try(:path_ids)
    HostgroupClass.where(:hostgroup_id => hg_ids).pluck(:puppetclass_id)
  end

  def parent_classes
    return [] unless host.hostgroup
    host.hostgroup.classes(environment)
  end

  # returns the list of puppetclasses a host is in.
  def puppetclasses_names
    all_puppetclasses.collect {|c| c.name}
  end

  def clear_puppetinfo(force = false)
    return unless host
    return if !force && environment && host.puppet_aspect

    host.puppetclasses = []
    host.config_groups = []
  end

  def info
    param = {}
    param["puppetmaster"] = puppetmaster
    if SETTINGS[:unattended]
      param["puppet_ca"]    = puppet_ca_server if puppetca?
    end
    param["foreman_env"]  = environment.to_s if environment and environment.name

    classes = if Setting[:Parametrized_Classes_in_ENC] && Setting[:Enable_Smart_Variables_in_ENC]
                lookup_keys_class_params
              else
                puppetclasses_names
              end

    info_hash = {}
    info_hash['classes'] = classes
    info_hash['parameters'] = param
    info_hash['environment'] = param["foreman_env"] if Setting["enc_environment"] && param["foreman_env"]

    info_hash
  end

  def lookup_keys_class_params
    Classification::ClassParam.new(:host => host).enc
  end

  def provisioning_template_options(base_options)
    base_options[:environment_id] ||= environment_id
    base_options
  end

  def self.hostgroup_inherited_attributes
    %w{puppet_proxy_id puppet_ca_proxy_id environment_id}
  end

  def self.inherited_attributes(hostgroup, aspect_attributes)
    aspect_attributes ||= {}
    inherited_attributes = hostgroup_inherited_attributes - aspect_attributes.keys

    inherited_attributes.each do |attribute|
      value = hostgroup.send("inherited_#{attribute}")
      aspect_attributes[attribute] = value
    end
    aspect_attributes
  end

  def self.populate_fields_from_facts(host, importer, type, proxy_id)
    aspect = host.puppet_aspect || host.build_puppet_aspect
    if Setting[:update_environment_from_facts]
      aspect.set_non_empty_values importer, [:environment]
    else
      aspect.environment ||= importer.environment unless importer.environment.blank?
    end

    aspect.puppet_proxy_id ||= proxy_id

    aspect.save(:validate => false)
  end
end
