require "sinatra/base"
require 'rack/attack'
require_relative "lib/cms/lib"

class App < Sinatra::Base
  use CMS::AdminRoutes
  use CMS::ApiRoutes
  use CMS::Auth
  # use Rack::Attack

  configure do
    CMS::Config.load
    CMS::Auth.enabled = true

    # Rack::Attack.enabled = true

    # throttle('requests_per_minute', limit: 60, period: 60) do |req|
    #   req.ip
    # end

    # throttle('login_attempts_per_hour', limit: 5, period: 3600) do |req|
    #   req.ip if req.path == '/login' && req.post?
    # end

    # Rack::Attack.throttled_response = lambda do |env|
    #   [ 429, # Too Many Requests
    #     { "Content-Type" => "text/plain" },
    #     ["Rate limit exceeeded. Try again later.\n"]
    #   ]
    # end
  end

  helpers do
    def protected!
      redirect "/login" unless authorized?
    end

    def authorized?
      !!session[:user_id]
    end
  end

  before do
    @is_signed_in = authorized?
  end

  get "/" do
    "Hello world!"
  end

  get "/protected" do
    protected!
    erb "This is protected data!!"
  end

  get "/login" do
    @error = params['error'] == 'invalidCredentials' ? 'Invalid credentials' : nil
    erb :login
  end

  post "/login" do
    success = Auth.sign_in(
      username: params[:username],
      password: params[:password],
    )
    redirect "/" if success
    status 401
    redirect "/login?error=invalidCredentials"
  end

  get "/logout" do
    Auth.sign_out
  end

  post "/logout" do
    Auth.sign_out
  end
end
