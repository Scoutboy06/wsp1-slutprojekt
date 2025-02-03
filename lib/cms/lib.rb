require "sinatra/base"

class CMS < Sinatra::Base
  get '/admin/' do
    '<h1>Hello world!</h1>'
  end

  get '/api/users/1' do
    content_type :json
    '{ "hello": "world" }'
  end
end
