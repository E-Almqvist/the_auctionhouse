#!/usr/bin/ruby -w

DEBUG = ARGV[0] == "debug"

require "sinatra"
require "sinatra/reloader" if DEBUG
require "slim"
require "sqlite3"
require "sassc"
require "colorize"
require "bcrypt"

require_relative "config.rb"
require_relative "debug.rb"
require_relative "lib/database.rb"
require_relative "func.rb"

require_relative "db_init.rb"
require_relative "db_models.rb"

enable :sessions
db = db_init

# Routes
get "/style.css" do
	sass :"stylesheets/style", style: :compressed
end

get "/" do
	serve :index
end

get "/login" do
	serve :"user/login"
end

get "/register" do
	info = session[:error_msg] != nil ? {error_msg: session[:error_msg]} : {}
	session[:error_msg] = nil
	serve :"user/register", info
end

# API stuff
post "/user" do
	# create user
	user = db.get_table :User

	email = params[:email]
	name = params[:name]
	password = params[:password]
	password_confirm = params[:password_confirm]

	status, ret = user.register(email, name, password, password_confirm)
	Console::debug "STATUS: #{status}", ret
	if !status then # if something went wrong then return to 0
		session[:error_msg] = ret
		redirect "/register"
	else # if everything went right then continue
		redirect "/login"
	end
end

post "/user/login" do
	# login user
	redirect "/"
end

