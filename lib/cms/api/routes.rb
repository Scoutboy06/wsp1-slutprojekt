require "sinatra"
require "bcrypt"
require "json"

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
    @setting = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?

    limit = params[:limit]&.to_i || 50
    offset = (params[:page]&.to_i * limit) : 0

    data = @db.execute(
      "SELECT *
      FROM #{@setting.slug}
      LIMIT ?
      OFFSET ?
    ", [limit, offset])

    data.to_json
  end

  get "/api/collections/:slug/:id" do |slug, id|
    @setting = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?

    data = @db.execute(
      "SELECT * FROM #{@setting.slug} WHERE id = ?",
      [id]
    ).first

    data.to_json
  end

  post "/api/collections/:slug" do |slug|
    @setting = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?

    data = JSON.parse(request.body.read)

    field_names = @setting.fields.map { |field| field.name }
    field_values = @setting.fields.map do |field|
      value = data.fetch(field.name, nil)
      value = 1 if value == true
      value = 0 if value == false
      value = BCrypt::Password.create(value) if field.type == "password"
      value
    end

    exec_str = "INSERT INTO #{@setting.slug}
      (#{field_names.join(", ")})
      VALUES (#{field_names.map { |_| "?" }.join(",")})
    "

    puts exec_str
    p field_values

    @db.execute(exec_str, field_values)

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
