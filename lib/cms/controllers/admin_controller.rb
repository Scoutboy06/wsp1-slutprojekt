require 'sinatra/base'
require_relative '../lib'
require_relative '../models/media'

class AdminController < Sinatra::Base
  configure do
    set :root, File.dirname(__FILE__)
    set :views, File.join(root, '../views/admin')
    set :public_folder, File.join(root, 'public')
  end

  helpers do
    # Renders a partial template without a layout.
    # @param [Symbol, String] template The name of the template file (without extension).
    # @param [Hash] options Local variables to pass to the template.
    # @return [String] The rendered partial HTML.
    def partial(template, options = {})
      erb template.to_sym, options.merge!(layout: false)
    end
  end

  before do
    return unless request.path_info.start_with?('/admin')

    if CMS::Auth.enabled
      s = CMS::Auth.session

      if !s || !s[:user_id] || s[:is_admin] == false
        status 401
        redirect '/login'
        return
      end
    end

    @collections = CMS::Config.collections
    @globals = CMS::Config.globals
    @db = CMS::Config.db

    @settings = []

    @settings << { name: 'Collections', slug: 'collections', items: @collections } unless @collections.nil?

    @settings << { name: 'Globals', slug: 'globals', items: @globals } unless @collections.nil?
  end

  # @method GET
  # @path /admin/?
  # Displays the main admin dashboard/index page.
  # Requires authentication (enforced by the `before` filter).
  # @return [String] Renders the admin index view (erb :index).
  get '/admin/?' do
    erb :index
  end

  # @method GET
  # @path /admin/collections
  # Redirects to the view for the first available collection.
  # If no collections are defined, redirects back to the admin dashboard.
  # Requires authentication.
  # @return [void] Performs a redirect.
  get '/admin/collections' do
    redirect '/admin' if @collections.empty?
    redirect "/admin/collections/#{@collections[0].slug}"
  end

  # @method GET
  # @path /admin/collections/:slug
  # Displays a list of entries for a specific collection, with pagination.
  # Requires authentication.
  # @param [String] slug The unique identifier (slug) of the collection.
  # @param [Integer] limit Query parameter for pagination (default: 50). (Optional)
  # @param [Integer] page Query parameter for pagination page number (default: 0). (Optional)
  # @return [String] Renders the collection entries view (erb :entry_details).
  # @raise [Sinatra::NotFound] Halts with 404 if the collection slug does not exist.
  get '/admin/collections/:slug' do |slug|
    @collection = @collections.find { |c| c.slug == slug }
    halt 404 if @collection.nil?

    limit = Integer(params[:limit], exception: false) || 50
    offset = (Integer(params[:page], exception: false) || 0) * limit

    @entries = @collection.nested_select(
      limit: limit,
      offset: offset
    )

    erb :entry_details
  end

  # @method GET
  # @path /admin/collections/:slug/new
  # Displays the form to create a new entry for a specific collection.
  # Requires authentication.
  # @param [String] slug The slug of the collection to add an entry to.
  # @return [String] Renders the new entry form (erb :new_entry).
  # @raise [Sinatra::NotFound] Halts with 404 if the collection slug does not exist.
  get '/admin/collections/:slug/new' do |slug|
    @setting = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?
    erb :new_entry
  end

  # @method GET
  # @path /admin/collections/:slug/:id/edit
  # Displays the form to edit an existing entry within a collection.
  # Requires authentication.
  # @param [String] slug The slug of the collection.
  # @param [String] id The ID of the entry to edit.
  # @return [String] Renders the edit entry form (erb :edit_entry).
  # @raise [Sinatra::NotFound] Halts with 404 if the collection or entry ID is not found.
  get '/admin/collections/:slug/:id/edit' do |slug, id|
    @collection = @collections.find { |c| c.slug == slug }
    halt 404 if @collection.nil?

    @entry = @collection.nested_select(id: id).first
    halt 404 if @entry.nil?

    erb :edit_entry
  end

  # @method POST
  # @path /admin/collections/:__slug/:__id/edit
  # Processes the submission of the edit entry form. Updates the entry in the database.
  # Requires authentication.
  # @param [String] __slug The slug of the collection (from path).
  # @param [String] __id The ID of the entry to update (from path).
  # @param [Hash] params Contains the form data submitted for the entry update.
  # @return [void] Redirects back to the edit form upon completion.
  # @raise [Sinatra::NotFound] Halts with 404 if the collection slug does not exist.
  post '/admin/collections/:__slug/:__id/edit' do |__slug, __id|
    @collection = @collections.find { |c| c.slug == __slug }
    halt 404 if @collection.nil?

    @collection.update(
      data: params.except('__slug', '__id'),
      id: __id.to_i
    )

    redirect "/admin/collections/#{__slug}/#{__id}/edit"
  end

  # @method POST
  # @path /admin/collections/:__slug
  # Processes the submission of the new entry form. Creates a new entry in the database.
  # Requires authentication.
  # @param [String] __slug The slug of the collection (from path).
  # @param [Hash] params Contains the form data submitted for the new entry.
  # @return [void] Sets status 201 and redirects to the collection's entry list.
  # @raise [Sinatra::NotFound] Halts with 404 if the collection slug does not exist.
  post '/admin/collections/:__slug' do |slug|
    @setting = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?

    @setting.insert(params.except('__slug'))

    status 201
    redirect "/admin/collections/#{@setting.slug}"
  end

  # @method GET
  # @path /admin/globals/:slug
  # Displays the details/edit form for a specific global setting.
  # Requires authentication.
  # @param [String] slug The slug of the global setting.
  # @return [String] Renders the global setting details/edit view (erb :entry_details).
  # @raise [Sinatra::NotFound] Halts with 404 if the global slug does not exist.
  get '/admin/globals/:slug' do |slug|
    @setting = @globals.find { |g| g.slug == slug }
    halt 404 if @setting.nil?
    erb :entry_details
  end
end
