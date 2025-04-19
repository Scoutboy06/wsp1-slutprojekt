require 'sinatra/base'
require_relative '../utils/valid_email'

class AuthController < Sinatra::Base
  use Rack::Session::Cookie, key: 'rack.session',
                             path: '/',
                             secret: ENV['SESSION_SECRET']

  class << self
    attr_accessor :enabled, :admin_column, :current_session
  end

  helpers do
    def protected!
      redirect '/login' unless @is_signed_in
    end

    def authorized?
      !!session[:user_id]
    end
  end

  before do
    self.class.current_session = session
  end

  def self.session
    current_session
  end

  def self.get_current_user
    return nil unless session[:user_id]

    user_col = CMS.collection('users')
    raise 'User collection not defined' if user_col.nil?

    user_col.select_by(id: session[:user_id]).first
  end

  def self.sign_in(email:, password:)
    user_col = CMS::Config.collections.find { |c| c.is_a?(User) }
    raise 'User collection not defined' if user_col.nil?

    user = user_col.select_by(email: email, limit: 1).first
    return false if user.nil?

    hashed_password = user['password'].to_s
    bcrypt_db_pass = BCrypt::Password.new(hashed_password)
    is_valid_pass = bcrypt_db_pass == password

    if is_valid_pass
      session[:user_id] = user['id']
      session[:is_admin] = admin_column&.then { !user[admin_column].to_i.zero? }
      true
    else
      false
    end
  end

  # @param username [String] the desired username
  # @param email [String] the user's email address
  # @param password [String] the user's password
  # @return [Array]
  #   Returns [user_id, nil] on success or [nil, error_code] on failure.
  def self.sign_up(username:, email:, password:)
    user_col = CMS.collection('users')
    raise 'User collection not defined' if user_col.nil?

    return [nil, 'invalidUsername'] unless username.is_a?(String) && username.length > 0
    return [nil, 'invalidEmail'] unless valid_email?(email)

    existing_user = user_col.select_by(email: email, limit: 1).first
    return [nil, 'emailAlreadyInUse'] unless existing_user.nil?

    user_col.insert({
                      'username' => username,
                      'email' => email,
                      'password' => password
                    })

    user_id = CMS::Config.db.last_insert_row_id
    session[:user_id] = user_id

    [user_id, nil]
  end

  def self.sign_out
    session.clear
  end
end
