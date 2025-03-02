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

      @db = DB

      if @collections.nil?
        @collections = COLLECTIONS.map { |c| Collection.from_hash(c) }
        @collections << Media.get_collection
        @collections.each { |c| c.setup_db(@db) }
      end

      if @globals.nil?
        @globals = GLOBALS.map { |g| Global.from_hash(g) }
        # @globals.each { |g| g.setup_db(@db) }
      end
    end

    def self.collections
      @collections
    end

    def self.globals
      @globals
    end

    def self.db
      @db
    end
  end
end

CMS::Config.load
