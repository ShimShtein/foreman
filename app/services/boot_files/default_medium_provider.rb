module BootFiles
  class DefaultMediumProvider
    def self.provides?(entity)
      os = entity.operating_system
      medium = entity.medium
      arch = entity.architecture

      medium && os.media.include?(medium) && os.architectures.include?(arch)
    end

    def self.errors(entity)
      errors = []
      os = entity.operating_system
      medium = entity.medium
      arch = entity.architecture

      errors << N_("%{os} medium was not set for host '%{host}'") % { :host => entity, :os => os } if medium.nil?
      errors << N_("Invalid medium '%{medium}' for '%{os}'") % { :medium => medium, :os => os } unless os.media.include?(medium)
      errors << N_("Invalid architecture '%{arch}' for '%{os}'") % { :arch => arch, :os => os } unless os.architectures.include?(arch)
      errors
    end

    def medium_uri(path = "", &block)
      url ||= entity.medium.path if entity.medium.present?
      url ||= ''
      medium_vars_to_uri(url, entity.architecture.name, entity.operatingsystem, &block)
    end

    def interpolate_vars(pattern)
      medium_vars_to_uri(pattern, entity.architecture.name, entity.operatingsystem)
    end

    private

    def medium_vars_to_uri(url, arch, os, &block)
      URI.parse(interpolate_medium_vars(url, arch, os, &block)).normalize
    end

    def interpolate_medium_vars(path, arch, os)
      return "" if path.empty?

      path.gsub('$arch', '%{arch}').
           gsub('$major',  '%{major}').
           gsub('$minor',  '%{minor}').
           gsub('$version', '%{version}').
           gsub('$release', '%{release}')

      vars = medium_vars(arch, os)
      if block_given?
        yield(vars)
      end

      path % vars
    end

    def medium_vars(arch, os)
      {
        arch: arch,
        major: os.major,
        minor: os.minor,
        version: os.minor.blank? ? os.major : [os.major, os.minor].compact.join('.'),
        release: os.release_name.blank? ? '' : os.release_name
      }
    end
  end
end
