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

before do 
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


