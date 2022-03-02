#!/usr/bin/ruby -w

DEBUG = ARGV[0] == "debug" 

require "sinatra" 
require "sinatra/reloader" if DEBUG # reload stuff
require "slim" # template
require "sqlite3" # db
require "sassc" # SASS -> CSS precompiler
require "colorize" # colors for debug
require "bcrypt" # password digest
# TODO: remove redcarpet dep
require "redcarpet" # markdown renderer
require "mini_magick" # image manipulation

require_relative "config.rb" # config stuff
require_relative "debug.rb" # debug methods
require_relative "lib/database.rb" # database library
require_relative "func.rb" # usefull methods
require_relative "const.rb" # constants

require_relative "db_init.rb" # db init (pre server init
require_relative "db_models.rb" # db models (i.e. User, Roles etc)

if DEBUG then
	also_reload "lib/*"
	also_reload "func.rb"
	also_reload "const.rb"
	also_reload "config.rb"
	also_reload "db_models.rb"
	also_reload "db_init.rb"
end

enable :sessions
db_init

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

get "/login" do
	serve :"user/login", layout: :empty
end

get "/register" do
	serve :"user/register", layout: :empty
end

get "/profile/:id" do
	id = params[:id].to_i
	userobj = User.find_by_id id

	if userobj then
		serve :"user/profile", {user: userobj}
	else
		serve :"404"
	end
end

get "/profile" do 
	if is_logged_in then
		redirect "/profile/#{session[:userid]}"
	else
		redirect "/login"
	end
end

# Posts
get "/profile/:id/posts" do
	serve :"user/posts", {user: User.find_by_id(params[:id].to_i)}
end

# Reputation
get "/profile/:id/rep" do
	serve :"user/rep", {user: User.find_by_id(params[:id].to_i)}
end

# Settings
get "/settings" do
	serve :"user/settings"
end

# API stuff
post "/register" do
	email = params[:email]
	name = params[:name]
	password = params[:password]
	password_confirm = params[:password_confirm]

	status, ret = User.register(email, name, password, password_confirm)
	Console.debug "/register STATUS: #{status}", ret
	if !status then # if something went wrong then return to 0
		session[:error_msg] = ret
		redirect "/register"
	else # if everything went right then continue
		redirect "/login"
	end
end

post "/login" do
	email = params[:email]
	password = params[:password]

	status, ret = User.login(email, password)
	if !status then # ret = error message
		session[:error_msg] = ret
		redirect "/login"
	else # ret = userid
		session[:userid] = ret 
		redirect "/"
	end
end

post "/logout" do
	session.clear
	redirect "/"
end

