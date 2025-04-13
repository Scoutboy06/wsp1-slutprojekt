require "sinatra/base"
require_relative "lib/cms/lib"

class App < Sinatra::Base
  use CMS::AdminRoutes
  use CMS::ApiRoutes
  use CMS::Auth

  configure do
    CMS::Config.load
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
    erb :login
  end

  post "/login" do
    success = Auth.sign_in(
      session,
      username: params[:username],
      password: params[:password],
    )
    redirect "/?success=true" if success
    redirect "/login?error=invalidCredentials"
  end

  post "/logout" do
    Auth.sign_out(session)
  end
end
