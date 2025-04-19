require 'sinatra/base'
require 'rack/attack'
require_relative 'lib/cms/lib'
require_relative 'lib/cms/controllers/admin_controller'
require_relative 'lib/cms/controllers/api_controller'
require_relative 'lib/cms/controllers/auth_controller'

class App < Sinatra::Base
  use CMS::AdminRoutes
  use CMS::ApiRoutes
  use CMS::Auth
  use Rack::Attack

  configure do
    CMS::Config.load
    CMS::Auth.enabled = true
    CMS::Auth.admin_column = 'admin'

    Rack::Attack.enabled = true

    # Rack::Attack.throttle('requests_per_minute', limit: 60, period: 60) do |req|
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
    # Ensures the user is authenticated. Redirects to /login if not.
    # @return [void]
    def protected!
      redirect '/login' unless authorized?
    end

    # Checks if a user session exists.
    # @return [Boolean] true if the user is logged in, false otherwise.
    def authorized?
      !!session[:user_id]
    end
  end

  before do
    @is_signed_in = authorized?

    case params['error']
    when 'invalidCredentials'
      @error = 'Invalid credentials'
    when 'invalidUsername'
      @error = 'Invalid username'
    when 'invalidEmail'
      @error = 'Invalid email'
    when 'emailAlreadyInUse'
      @error = 'Email is already in use'
    end
  end

  # @method GET
  # @path /
  # Displays a simple welcome message.
  # @return [String] The "Hello world!" message.
  get '/' do
    'Hello world!'
  end

  # @method GET
  # @path /protected
  # Displays protected content, requires authentication.
  # Redirects to /login if the user is not authenticated.
  # @return [String] Renders the protected content view if authorized.
  get '/protected' do
    protected!
    erb 'This is protected data!!'
  end

  # @method GET
  # @path /login
  # Displays the login form. Shows an error message if redirected from a failed login attempt.
  # @param [String] error Query parameter. If value is 'invalidCredentials', displays an error. (Optional)
  # @return [String] Renders the login form (erb :login).
  get '/login' do
    erb :login
  end

  # @method POST
  # @path /login
  # Processes the login form submission.
  # Attempts to authenticate the user using provided credentials.
  # Redirects to '/' on successful login.
  # Redirects back to '/login?error=invalidCredentials' on failure.
  # @param [String] email The email submitted via the form.
  # @param [String] password The password submitted via the form.
  # @return [void] Performs a redirect based on authentication result.
  post '/login' do
    success = CMS::Auth.sign_in(
      email: params[:email],
      password: params[:password]
    )
    redirect(params[:redirect] || '/') if success
    status 401
    redirect '/login?error=invalidCredentials'
  end

  get '/signup' do
    erb :signup
  end

  post '/signup' do
    _, error = Auth.sign_up(
      username: params[:username],
      email: params[:email],
      password: params[:password]
    )
    if error
      status 400
      redirect "/signup?error=#{error}"
    else
      status 201
      redirect '/'
    end
  end

  # @method GET
  # @path /logout
  # Logs the current user out by clearing their session.
  # @return [void]
  get '/logout' do
    Auth.sign_out
    redirect '/'
  end

  # @method POST
  # @path /logout
  # Logs the current user out (alternative method, often used with forms).
  # @return [void]
  post '/logout' do
    Auth.sign_out
  end
end
