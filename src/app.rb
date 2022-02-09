#!/usr/bin/ruby -w

DEBUG = ARGV[0] == "debug"

require "sinatra"
require "sinatra/reloader" if DEBUG
require "slim"
require "sqlite3"
require "sassc"
require "colorize"
require "bcrypt"

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
	slim :index, locals: {info: init_info}
end

get "/login" do
	slim :"user/login", locals: {info: init_info}
end

get "/register" do
	slim :"user/register", locals: {info: init_info}
end

# API stuff
post "/user" do
	# create user
	user = db.get_table :User

	email = params[:email]
	name = params[:name]
	password = params[:password]
	password_confirm = params[:password_confirm]

	status, info = user.register(email, name, password, password_confirm)
	if !status then # if something went wrong then return to 0
		redirect "/register", locals: {info: init_info(info)}	
	else # if everything went right then continue
		redirect "/login", locals: {info: init_info(info)}
	end
end

post "/user/login" do
	# login user
	redirect "/"
end

