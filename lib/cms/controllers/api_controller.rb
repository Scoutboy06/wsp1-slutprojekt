require 'sinatra'
require 'bcrypt'
require 'json'
require_relative '../models/collection'

class ApiController < Sinatra::Base
  before do
    content_type :json

    @collections = CMS::Config.collections
    @globals = CMS::Config.globals
    @db = CMS::Config.db

    @settings = []

    @settings << { name: 'Collections', slug: 'collections', items: @collections } unless @collections.nil?

    @settings << { name: 'Globals', slug: 'globals', items: @globals } unless @collections.nil?
  end

  # @method GET
  # @path /api/collections/:slug
  # Retrieves a list of entries for a specific collection as JSON.
  # Supports pagination via query parameters.
  # @param [String] slug The slug of the collection.
  # @param [Integer] limit Query parameter for pagination (default: 50). (Optional)
  # @param [Integer] page Query parameter for pagination page number (default: 0). (Optional)
  # @return [String] JSON array of collection entries.
  # @raise [Sinatra::NotFound] Halts with 404 (JSON response) if the collection slug does not exist.
  get '/api/collections/:slug' do |slug|
    @collection = @collections.find { |c| c.slug == slug }
    halt 404 if @collection.nil?
    limit = Integer(params[:limit], exception: false) || 50
    offset = (Integer(params[:page], exception: false) || 0) * limit

    data = @collection.nested_select(
      limit: limit,
      offset: offset
    )
    data.to_json
  end

  # @method GET
  # @path /api/collections/:slug/:id
  # Retrieves a single entry from a collection by its ID as JSON.
  # @param [String] slug The slug of the collection.
  # @param [String] id The ID of the entry to retrieve.
  # @return [String] JSON object representing the single entry.
  # @raise [Sinatra::NotFound] Halts with 404 (JSON response) if the collection or entry ID is not found.
  get '/api/collections/:slug/:id' do |slug, id|
    @collection = @collections.find { |c| c.slug == slug }
    halt 404 if @collection.nil?

    data = @collection.select(id: id).first
    data.to_json
  end

  # @method POST
  # @path /api/collections/:slug
  # Creates a new entry in a collection based on JSON data in the request body.
  # @param [String] slug The slug of the collection.
  # @param [String] request.body The JSON payload representing the new entry data.
  # @return [String] JSON response containing the ID of the newly created entry.
  # @raise [Sinatra::NotFound] Halts with 404 (JSON response) if the collection slug does not exist.
  post '/api/collections/:slug' do |slug|
    @collection = @collections.find { |c| c.slug == slug }
    halt 404 if @collection.nil?

    data = JSON.parse(request.body.read)
    @collection.insert(data)

    status 201
    @db.last_insert_row_id.to_json
  end

  # @method DELETE
  # @path /api/collections/:slug/:id
  # Deletes an entry from a collection by its ID.
  # @param [String] slug The slug of the collection.
  # @param [String] id The ID of the entry to delete.
  # @return [void] Returns status 200 OK on successful deletion.
  # @raise [Sinatra::NotFound] Halts with 404 (JSON response) if the collection slug or entry ID does not exist.
  delete '/api/collections/:slug/:id' do |slug, id|
    @collection = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?

    @collection.delete(id.to_i)
    rows_deleted = @db.changes

    if rows_deleted > 0
      status 200
    else
      halt 404, { error: 'Record not found' }.to_json
    end
  end
end
