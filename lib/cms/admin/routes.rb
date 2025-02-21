require "sinatra/base"
require_relative "../lib"

class AdminRoutes < Sinatra::Base
  before do
    @collections = CMS::Config.collections
    @globals = CMS::Config.globals
    @db = CMS::Config.db

    @settings = []

    if !@collections.nil?
      @settings << { name: "Collections", slug: "collections", items: @collections }
    end

    if !@collections.nil?
      @settings << { name: "Globals", slug: "globals", items: @globals }
    end
  end

  get "/admin" do
    erb :index
  end

  get "/admin/collections" do
    redirect "/admin" if @collections.empty?
    redirect "/admin/collections/#{@collections[0].slug}"
  end

  get "/admin/collections/:slug" do |slug|
    @setting = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?

    limit = 10

    @entries = @db.execute("SELECT * FROM #{@setting.slug} LIMIT ?", [limit])

    erb :setting_details
  end

  get "/admin/collections/:slug/new" do |slug|
    @setting = @collections.find { |c| c.slug == slug}
    halt 404 if @setting.nil?
    erb :new_setting
  end

  get "/admin/globals/:slug" do |slug|
    @setting = @globals.find { |g| g.slug == slug }
    halt 404 if @setting.nil?
    erb :setting_details
  end
end
