require "sinatra/base"
require_relative "lib/cms/lib"

class App < Sinatra::Base
  use CMS

  get "/" do
    "Hello world!"
  end
end

