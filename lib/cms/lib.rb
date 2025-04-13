require_relative "admin/routes"
require_relative "api/routes"
require_relative "lib/collection"
require_relative "lib/global"
require_relative "lib/auth_provider"
require_relative "lib/user"

module CMS
  AdminRoutes = ::AdminRoutes
  ApiRoutes = ::ApiRoutes
  Auth = ::Auth

  def self.build_user_config(**kwargs)
    User.build_config(**kwargs)
  end

  def self.build_media_config(**kwargs)
    Media.build_config(**kwargs)
  end

  def self.collection(slug)
    @collections.find { |col| col.slug == slug }
  end

  module Config
    CONFIG_FILE = File.expand_path("../../cms_config.rb", __dir__)

    def self.load
      require CONFIG_FILE

      @db = DB

      if @collections.nil?
        @collections = COLLECTIONS.map { |c| Collection.from_hash(c) }
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
