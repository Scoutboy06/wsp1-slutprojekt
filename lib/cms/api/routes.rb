require "sinatra"
require "bcrypt"
require "json"
require_relative "../lib/collection"

class ApiRoutes < Sinatra::Base
  before do
    content_type :json

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

  get "/api/collections/:slug" do |slug|
    @collection = @collections.find { |c| c.slug == slug }
    halt 404 if @collection.nil?
    limit = Integer(params[:limit], exception: false) || 50
    offset = (Integer(params[:page], exception: false) || 0) * limit

    data = @collection.nested_select(
      all_collections: @collections,
      limit: limit,
      offset: offset,
      db: @db,
    )
    data.to_json
  end

  get "/api/collections/:slug/:id" do |slug, id|
    @collection = @collections.find { |c| c.slug == slug }
    halt 404 if @collection.nil?

    data = @collection.select(db: @db, id: id).first
    data.to_json
  end

  post "/api/collections/:slug" do |slug|
    @collection = @collections.find { |c| c.slug == slug }
    halt 404 if @collection.nil?

    data = JSON.parse(request.body.read)
    @collection.insert(db: @db, data: data)

    status 201
    @db.last_insert_row_id.to_json
  end

  delete "/api/collections/:slug/:id" do |slug, id|
    @setting = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?

    @db.execute("DELETE FROM #{@setting.slug} WHERE id = ?", [id.to_i])
    rows_deleted = @db.changes

    if rows_deleted > 0
      status 200
    else
      halt 404, { error: "Record not found" }.to_json
    end
  end
end
