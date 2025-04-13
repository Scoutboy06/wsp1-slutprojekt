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
    user_col = CMS::Config.collections.find { |c| c.is_a?(User) }
    raise "User collection not defined" if user_col.nil?

    user = user_col.select_by(username: username, limit: 1).first
    return false if user.nil?

    hashed_password = user['password'].to_s
    bcrypt_db_pass = BCrypt::Password.new(hashed_password)
    is_valid_pass = bcrypt_db_pass == password

    if is_valid_pass
      session[:user_id] = user['id']
      true
    else
      false
    end
  end

  def self.sign_out(session)
    session.clear
  end
end
