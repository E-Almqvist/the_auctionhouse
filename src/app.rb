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

def auth_denied(msg=AUTH_ERRORS[:denied], status=403, ret="/")
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
		flash[:success] = "Account created! Please login."
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
	flash[:success] = "Successfully logged out!"
	redirect "/"
end

post "/user/update" do
	id = (get_current_user.admin? and params[:id]) ? params[:id].to_i : session[:userid]
	p "##########################"
	puts "id=#{id}"
	p "##########################"

	data = {
		name: params["displayname"].chomp,
		bio_text: params["bio"].chomp
	}

	if params[:image] then
		imgdata = params[:image][:tempfile] 
		save_image imgdata.read, "./public/avatars/#{id}.png" # save the image
		data[:avatar_url] = "/avatars/#{id}.png" # update image path
	end

	success, msg = User.find_by_id(id).update_creds data # update the user creds
	if not success then flash[:error] = msg end	

	flash[:success] = "Profile updated."
	redirect back
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

# Admin panel
get "/admin" do
	flags = get_current_user.flags

	user = get_current_user
	banned unless !user.banned? # reject the user if banned
	auth_denied unless user.flags != 0 # reject the user if he/she has no roles

	data = {
		roles: Role.get_all,
		users: User.get_all,
		categories: Category.get_all
	}

	serve :"admin/index", {flags: flags, data: data}
end

# ADMIN USER MANAGEMENT
get "/admin/users/:id/ban" do
	auth_denied unless get_current_user.admin?
	id = params[:id].to_i

	user = User.find_by_id id
	user.banned = true

	flash[:error] = "Banned user '#{user.name}'"

	redirect back
end

get "/admin/users/:id/unban" do
	auth_denied unless get_current_user.admin?
	id = params[:id].to_i

	user = User.find_by_id id
	user.banned = false

	flash[:success] = "Unbanned user '#{user.name}'"

	redirect back
end

get "/admin/users/:id/edit" do
	auth_denied unless get_current_user.admin?
	id = params[:id].to_i
	user = User.find_by_id id

	serve :"admin/users/edit", {user: user}
end

post "/admin/users/rolegive" do
	user = get_current_user
	auth_denied unless user.permitted?(:roleman)

	user_id = params[:user_id].to_i
	role_id = params[:role_id].to_i

	auth_denied "You are not permitted to give that role!", 403, back if role_id == ROLES[:banned][:id]
	
	if user.role_ids.include?(role_id) or user.admin? then
		resp = User_Role_relation.give_role(user_id, role_id)

		flash[:success] = "Gave role to user." if resp 
		redirect back
	else
		auth_denied "You are not permitted to give that role!", 403, back
	end
end

post "/admin/users/rolerevoke" do
	user = get_current_user
	auth_denied unless user.permitted?(:roleman)

	user_id = params[:user_id].to_i
	role_id = params[:role_id].to_i

	auth_denied "You are not permitted to give that role!", 403, back if role_id == ROLES[:banned][:id]
	if user.admin? then
		resp = User_Role_relation.revoke_role(user_id, role_id)	
		flash[:success] = "Revoked role from user." if resp 
		redirect back
	else
		auth_denied "You are not permitted to give that role!", 403, back
	end
end


post "/admin/users/setmoney" do
	user = get_current_user
	auth_denied unless user.permitted? :moneyman

	id = params[:user_id].to_i
	money = params[:money].to_f
	target = User.find_by_id(id)

	target.balance = money

	flash[:success] = "Set users money to '#{money}'."

	redirect back
end

# ADMIN ROLE MANAGEMENT
def role_check(id)
	no_go_away if ROLE_IDS.include? id
	auth_denied unless get_current_user.permitted? :roleman
end

post "/admin/roles" do
	user = get_current_user
	auth_denied unless user.permitted? :roleman

	name = params[:name]
	color = params[:color]
	flags = params[:flags]

	flags = params[:flags].to_i
	flags = verify_flags(flags, user.flags)

	newid, resp = Role.create(name, color, flags)
	if newid then
		flash[:success] = "Successfully created role '#{name}'."
	else
		flash[:error] = resp 
	end
	redirect back
end

get "/admin/roles/:id/delete" do
	id = params[:id].to_i
	role_check id
	
	Role.delete "id = ?", id

	flash[:success] = "Removed role."
	redirect back
end

get "/admin/roles/:id/edit" do
	id = params[:id].to_i
	role_check id

	roleobj = Role.find_by_id id
	if roleobj then
		serve :"admin/roles/edit", {role: roleobj}
	else
		raise Sinatra::NotFound
	end
end

def verify_flags(flags, userflags)
	# TODO: check if this actually works
	# should work in practise but who knows
	newflags = flags & userflags # only give flags that the user have (max)
	flash[:error] = "You are not allowed those flags!" if newflags != flags
	return newflags
end

post "/admin/roles/:id/update" do
	id = params[:id].to_i
	user = get_current_user
	auth_denied unless user.permitted? :roleman

	flags = params[:flags].to_i
	flags = verify_flags(flags, user.flags)

	data = {
		name: params[:name],
		color: params[:color],
		flags: flags
	}
	resp = Role.edit id, data

	flash[:success] = "Updated role."
	redirect "/admin/roles/#{id}/edit"
end


# ADMIN CATEGORY MANAGEMENT
post "/admin/categories" do
	user = get_current_user
	auth_denied unless user.permitted? :cateman

	name = params[:name]
	color = params[:color]

	newid, resp = Category.create(name, color)
	if newid then
		flash[:success] = "Successfully created category '#{name}'."
	else
		flash[:error] = resp 
	end
	redirect back
end

get "/admin/categories/:id/delete" do
	id = params[:id].to_i
	user = get_current_user
	auth_denied unless user.permitted? :cateman
	
	Category.delete "id = ?", id

	flash[:success] = "Removed category."
	redirect back
end

get "/admin/categories/:id/edit" do
	id = params[:id].to_i
	user = get_current_user
	auth_denied unless user.permitted? :cateman

	catobj = Category.find_by_id id
	if catobj then
		serve :"admin/categories/edit", {category: catobj}
	else
		raise Sinatra::NotFound
	end
end

post "/admin/roles/:id/update" do
	id = params[:id].to_i
	user = get_current_user
	auth_denied unless user.permitted? :cateman

	data = {
		name: params[:name],
		color: params[:color],
	}
	resp = Category.edit id, data

	flash[:success] = "Updated category."
	redirect "/admin/roles/#{id}/edit"
end

