require "sinatra/base"

class ApiRoutes < Sinatra::Base
  get '/api/users/:id' do |id|
    content_type :json
    id.to_i
  end
end
