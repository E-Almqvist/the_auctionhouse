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
require "rmagick" # image manipulation

require_relative "config" # config stuff
require_relative "debug" # debug methods
require_relative "lib/database" # database library
require_relative "const" # constants
require_relative "func" # usefull methods

require_relative "db_init" # db init (pre server init
require_relative "db_models" # db models (i.e. User, Roles etc)

if DEBUG then
	also_reload "lib/*", "func.rb", "const.rb", "config.rb", "db_models.rb", "db_init.rb"
end

enable :sessions
db_init

before do 
	if !is_logged_in && request.path_info.start_with?(*AUTH_ROUTES) then
		session[:ret] = request.fullpath # TODO: return the user to the previous route
		session[:status] = 403
		session[:error_msg] = AUTH_ERRORS[:needed] 
		redirect "/login"
	end
end

not_found do 
	serve :"404"
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
		raise Sinatra::NotFound
	end
end

get "/profile" do 
	if is_logged_in then
		redirect "/profile/#{session[:userid]}"
	else
		redirect "/login"
	end
end

# Reputation
get "/profile/:id/rep" do
	userobj = User.find_by_id params[:id].to_i
	if userobj then
		serve :"user/rep", {user: userobj} 
	else
		raise Sinatra::NotFound
	end
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
	email = params[:email].strip
	password = params[:password].strip

	status, ret = User.login(email, password)
	if !status then # ret = error message
		session[:error_msg] = ret
		redirect "/login"
	else # ret = userid
		session[:userid] = ret 
		redirect "/"
	end
end

post "/user/logout" do 
	session.clear
	redirect "/"
end

post "/user/update" do
	data = {
		name: params["displayname"].chomp,
		bio_text: params["bio"].chomp
	}

	if params[:image] then
		imgdata = params[:image][:tempfile] 
		save_image imgdata.read, "./public/avatars/#{session[:userid]}.png" # save the image
		data[:avatar_url] = "/avatars/#{session[:userid]}.png" # update image path
	end

	success, msg = get_current_user.update_creds data # update the user creds
	if not success then session[:error_msg] = msg end	

	redirect "/settings"
end

