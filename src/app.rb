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

also_reload "lib/*"
also_reload "func.rb"
also_reload "config.rb"
also_reload "db_models.rb"
also_reload "db_init.rb"

enable :sessions
db_init

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
	serve :"user/register"
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
	Console.debug "/login STATUS: #{status}", ret
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

