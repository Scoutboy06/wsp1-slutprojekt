require "sinatra/base"
require_relative "../lib"
require_relative "../lib/media"

class AdminRoutes < Sinatra::Base
  configure do
    set :public_folder, 'lib/cms/public'
  end

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

  post "/admin/collections/:slug" do |slug|
    @setting = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?

    values = []

    for field in @setting.fields
      value = nil

      if field.type == "upload"
        file_meta = Media.upload(
          db: @db,
          tempfile: params[field.name][:tempfile],
          filename: params[field.name][:filename],
          file_path: "public/uploads/"
        )

        value = file_meta[:id]
      elsif field.type == "password"
        value = BCrypt::Password.create(params[field.slug])
      else
        value = params[field.name]
      end

      values.push(value)
    end

    exec_str = "INSERT INTO #{@setting.slug}
    (#{@setting.fields.map { |f| f.name }.join(', ')})
    VALUES (#{values.map { |_| "?" }.join(',')})"
    puts exec_str
    p values

    @db.execute(exec_str, values)

    status 201
  end

  get "/admin/globals/:slug" do |slug|
    @setting = @globals.find { |g| g.slug == slug }
    halt 404 if @setting.nil?
    erb :setting_details
  end
end
