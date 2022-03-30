#!/usr/bin/ruby -w

DEBUG = ARGV[0] == "debug" 

require "sinatra" 
require "sinatra/reloader" if DEBUG # reload stuff
require "sinatra/flash"
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
		flash[:error] = AUTH_ERRORS[:needed] 
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

# User stuff
get "/settings" do
	serve :"user/settings"
end

post "/register" do
	email = params[:email]
	name = params[:name]
	password = params[:password]
	password_confirm = params[:password_confirm]

	status, ret = User.register(email, name, password, password_confirm)
	Console.debug "/register STATUS: #{status}", ret
	if !status then # if something went wrong then return to 0
		flash[:error] = ret
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
		flash[:error] = ret
		redirect "/login"
	else # ret = userid
		session[:userid] = ret 
		redirect "/"
	end
end

get "/logout" do 
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
	if not success then flash[:error] = msg end	

	flash[:success] = "Updated profile"
	redirect "/settings"
end

# Auction stuff
get "/auctions" do
	title = params[:title]
	#categories = (params[:categories].split ",").map {|id| id.to_i} 
	#price_rng = (params[:price_rng].split "-").map {|p| p.to_i}
	isopen = params[:isopen]

	auctions = Auction.search title#, categories, price_rng, isopen
	serve :"auction/index", {auctions: auctions}
end

get "/auctions/new" do
	serve :"auction/new"
end

post "/auctions" do
	user_id = session[:userid]
	title = params[:title]
	description = params[:description]
	init_price = params[:init_price].to_f
	delta_time = params[:delta_time].to_i * 3600 # hours to seconds

	# Select the category ids
	category_choices = (params.select { |k, v| k.to_s.match(/^category-\d+/) }).map{ |k, v| v.to_i }
	
	newid, resp = Auction.create user_id, title, description, init_price, delta_time, category_choices

	if newid then
		flash[:success] = "Auction posted!"
		redirect "/auctions/#{newid}"
	else
		flash[:error] = resp
		redirect "/auctions/new"
	end
end

get "/auctions/:id" do
	id = params[:id].to_i
	auction_obj = Auction.find_by_id id

	if !auction_obj.nil? then
		serve :"auction/view", {auction: auction_obj}	
	else
		raise Sinatra::NotFound
	end
end

