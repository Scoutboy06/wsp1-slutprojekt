require_relative "admin/routes"
require_relative "api/routes"
require_relative "lib/collection"
require_relative "lib/global"

module CMS
  AdminRoutes = ::AdminRoutes
  ApiRoutes = ::ApiRoutes

  module Config
    CONFIG_FILE = File.expand_path("../../cms_config.rb", __dir__)

    def self.load
      require CONFIG_FILE

      @collections = COLLECTIONS.map { |c| Collection.from_hash(c) }
      @globals = GLOBALS.map { |g| Global.from_hash(g) }
    end

    def self.collections
      @collections
    end

    def self.globals
      @globals
    end
  end
end

CMS::Config.load
