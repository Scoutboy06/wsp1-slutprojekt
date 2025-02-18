require_relative "admin/routes"
require_relative "api/routes"

module CMS
  AdminRoutes = ::AdminRoutes
  ApiRoutes = ::ApiRoutes

  module Config
    CONFIG_FILE = File.expand_path("../../cms_config.rb", __dir__)

    def self.load
      require CONFIG_FILE
    end

    def self.collections
      COLLECTIONS
    end

    def self.globals
      GLOBALS
    end
  end
end

CMS::Config.load
