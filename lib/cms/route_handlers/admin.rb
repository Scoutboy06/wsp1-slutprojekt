require "sinatra/base"

class AdminRoutes < Sinatra::Base
  get "/admin/" do
    "<h1>Banger admin page👍</h1>"
  end
end
