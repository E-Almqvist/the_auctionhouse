#!/usr/bin/ruby -w

DEBUG = ARGV[0] == "debug" 

# DEPS
require "sinatra" 
require "sinatra/reloader" if DEBUG # reload stuff
require "sinatra/flash"
require "slim" # template
require "sqlite3" # db
require "sassc" # SASS -> CSS precompiler
require "colorize" # colors for debug
require "bcrypt" # password digest
require "rmagick" # image manipulation
require "fileutils" # file utils

# CONFIG ESC
require_relative "config" # config stuff
require_relative "const" # constants

# LIBS
require_relative "lib/debug" # debug methods
require_relative "lib/database" # database library
require_relative "lib/func" # usefull methods
require_relative "lib/db_init" # db init (pre server init
require_relative "lib/db_models" # db models (i.e. User, Roles etc)

if DEBUG then
	also_reload "lib/*", "config.rb", "const.rb", "routes/*"
end

enable :sessions
db_init

RATE_LIMITS ||= Hash.new(Hash.new(0))

not_found do 
	serve :"404"
end

def auth_denied(msg=AUTH_ERRORS[:denied], status=403, ret=back)
	session[:status] = status
	session[:ret] = ret
	flash[:error] = msg
	redirect ret
end

def no_go_away(ret=back)
	auth_denied "No! GO AWAY!", 403, ret
end

def banned(ret=back)
	auth_denied "You are banned!", 403, ret
end

def error(ret=back)
	auth_denied "Internal server error.", 500, ret
end

def ratelimit(delta_time, ret="/")
	auth_denied "Doing that a bit too fast... Please try again in #{delta_time} seconds.", 429, ret
end

before do 
	# Ratelimiting
	# check if route contains any of the protected ones
	# and if it is a POST request (dont care about GETs)
	if request.path_info.start_with?(*RATE_LIMIT_ROUTES_ALL) and request.request_method == "POST" then 
		RATE_LIMIT_ROUTES.each do |t, cfg|
			if request.path_info.start_with?(*cfg[:routes]) then
				dt = Time.now.to_i - RATE_LIMITS[t][request.ip]
				ratelimit(dt) unless dt > cfg[:time] # send a rate limit response if rate limited
				RATE_LIMITS[t][request.ip] = Time.now.to_i
			end
		end
	end

	# Authentication check
	route_auth_needed = request.path_info.start_with?(*AUTH_ROUTES)
	if !is_logged_in && route_auth_needed then
		session[:ret] = request.fullpath # TODO: return the user to the previous route
		session[:status] = 403
		flash[:error] = AUTH_ERRORS[:needed] 
		redirect "/login"
	elsif route_auth_needed && get_current_user.banned?
		banned
	end
end

# Routes
get "/style.css" do
	sass :"stylesheets/style", style: :compressed
end

get "/" do
	serve :index
end

get "/404" do
	serve :"404"
end

# Require all routes
Dir[File.join(__dir__, 'routes', '*.rb')].each { |file| require file }


