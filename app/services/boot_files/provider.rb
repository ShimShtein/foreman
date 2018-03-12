module BootFiles
  class Provider
    def self.provides?(entity)
      throw "self.provides? is not implemented for #{self.class.name}"
    end

    def self.errors(entity)
      []
    end

    def self.friendly_name
      self.name
    end

    def initialize(entity)
      @entity = entity
    end

    def medium_uri
      throw "medium_uri is not implemented for #{self.class.name}"
    end

    def boot_files_uri
      throw "boot_files_uri is not implemented for #{self.class.name}"
    end

    def unique_id
      @unique_id ||= Digest::SHA1.hexdigest(medium_uri.to_s)
    end

    private

    attr_reader :entity
  end
end
