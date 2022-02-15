#!/usr/bin/ruby -w

DEBUG = ARGV[0] == "debug"

require "sinatra"
require "sinatra/reloader" if DEBUG
require "slim"
require "sqlite3"
require "sassc"
require "colorize"
require "bcrypt"
require "gravatar"

require_relative "config.rb"
require_relative "debug.rb"
require_relative "lib/database.rb"
require_relative "func.rb"

require_relative "db_init.rb"
require_relative "db_models.rb"

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
	info = session[:error_msg] != nil ? {error_msg: session[:error_msg]} : {}
	session[:error_msg] = nil
	serve :"user/login"
end

get "/register" do
	info = session[:error_msg] != nil ? {error_msg: session[:error_msg]} : {}
	session[:error_msg] = nil
	serve :"user/register", info
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
	if !status then
		session[:error_msg] = ret
		redirect "/login"
	else
		session[:user] = User.new ret
		redirect "/"
	end
end

