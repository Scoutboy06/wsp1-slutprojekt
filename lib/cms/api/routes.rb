require "sinatra"
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

  post "/api/collections/:slug" do |slug|
    @setting = @collections.find { |c| c.slug == slug }
    halt 404 if @setting.nil?

    data = JSON.parse(request.body.read)

    field_names = @setting.fields.map { |field| field.name }
    field_values = field_names.map do |name|
      value = data.fetch(name, nil)
      value = 1 if value == true
      value = 0 if value == false
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
end
