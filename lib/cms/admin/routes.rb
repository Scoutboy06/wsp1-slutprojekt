require "sinatra/base"
require_relative "../lib"

class AdminRoutes < Sinatra::Base
  before do
    collections = CMS::Config.collections
    globals = CMS::Config.globals

    @settings = []

    if !collections.nil?
      @settings << { name: "Collections", slug: "collections", items: collections }
    end

    if !collections.nil?
      @settings << { name: "Globals", slug: "globals", items: globals }
    end
  end

  get "/admin/" do
    erb :index
  end
end
