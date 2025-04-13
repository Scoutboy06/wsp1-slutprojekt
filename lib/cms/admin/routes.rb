require "sinatra/base"
require_relative "../lib"
require_relative "../lib/media"

class AdminRoutes < Sinatra::Base
  configure do
    set :root, File.dirname(__FILE__) # Set root to the current directory
    set :views, File.join(root, "views") # Tell Sinatra where to find views
    set :public_folder, File.join(root, "public") # Tell Sinatra where to find public files
  end

  helpers do
    def partial(template, options = {})
      erb template.to_sym, options.merge!(:layout => false)
    end
  end

  before do
    return unless request.path_info.start_with?('/admin')

    if CMS::Auth.enabled
      puts "Hello"
      session = CMS::Auth.session
      if !session || !session[:user_id]
        status 401
        redirect '/login'
        return
      end
    end
    
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

  get "/admin/?" do
    erb :index
  end

  get "/admin/collections" do
    redirect "/admin" if @collections.empty?
    redirect "/admin/collections/#{@collections[0].slug}"
  end

  get "/admin/collections/:slug" do |slug|
    @collection = @collections.find { |c| c.slug == slug }
    halt 404 if @collection.nil?

    limit = Integer(params[:limit], exception: false) || 50
    offset = (Integer(params[:page], exception: false) || 0) * limit

    @entries = @collection.nested_select(
      limit: limit,
      offset: offset,
    )

    erb :entry_details
  end

  get "/admin/collections/:slug/new" do |slug|
    @setting = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?
    erb :new_entry
  end

  get "/admin/collections/:slug/:id/edit" do |slug, id|
    @collection = @collections.find { |c| c.slug == slug }
    halt 404 if @collection.nil?

    @entry = @collection.nested_select(id: id).first
    halt 404 if @entry.nil?

    erb :edit_entry
  end

  post "/admin/collections/:__slug/:__id/edit" do |__slug, __id|
    @collection = @collections.find { |c| c.slug == __slug }
    halt 404 if @collection.nil?

    @collection.update(
      data: params.except("__slug", "__id"),
      id: __id.to_i
    )

    redirect "/admin/collections/#{__slug}/#{__id}/edit"
  end

  post "/admin/collections/:__slug" do |slug|
    @setting = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?

    @setting.insert(params.except('__slug'))

    status 201
    redirect "/admin/collections/#{@setting.slug}"
  end

  get "/admin/globals/:slug" do |slug|
    @setting = @globals.find { |g| g.slug == slug }
    halt 404 if @setting.nil?
    erb :entry_details
  end
end
