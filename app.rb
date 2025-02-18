require "sinatra/base"
require_relative "lib/cms/lib"

class App < Sinatra::Base
  use CMS::AdminRoutes
  use CMS::ApiRoutes

  get "/" do
    "Hello world!"
  end
end
