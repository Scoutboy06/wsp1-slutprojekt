require_relative './models/models'
require_relative './controllers/admin_controller'
require_relative './controllers/api_controller'
require_relative './controllers/auth_controller'

module CMS
  AdminRoutes = ::AdminController
  ApiRoutes = ::ApiController
  Auth = ::AuthController

  def self.build_user_config(**kwargs)
    User.build_config(**kwargs)
  end

  def self.build_media_config(**kwargs)
    Media.build_config(**kwargs)
  end

  def self.collection(slug)
    CMS::Config.collections.find { |col| col.slug == slug }
  end

  def self.global(slug)
    CMS::Config.globals.find { |col| col.slug == slug }
  end

  def self.find_by_slug(slug)
    collection(slug) || global(slug)
  end

  module Config
    CONFIG_FILE = File.expand_path('../../cms_config.rb', __dir__)

    def self.load
      require CONFIG_FILE

      @db = DB

      if @collections.nil?
        @collections = COLLECTIONS.map { |c| Collection.from_hash(c) }
        @collections.each { |c| c.setup_db(@db) }
      end

      return unless @globals.nil?

      @globals = GLOBALS.map { |g| Global.from_hash(g) }
      @globals.each { |g| g.setup_db(@db) }
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
