require "sinatra/base"

class Auth < Sinatra::Base
  use Rack::Session::Cookie, key: "rack.session",
                             path: "/",
                             secret: ENV["SESSION_SECRET"]

  helpers do
    def protected!
      redirect "/login" unless @is_signed_in
    end

    def authorized?
      !!session[:user_id]
    end
  end

  def self.sign_in(session, username:, password:)
    session[:user_id]
  end

  def self.sign_out(session)
    session.clear
  end
end
