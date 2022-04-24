###############
# Admin panel #
###############

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

# Ban user
# @param [Integer] id
# @see User#banned=
get "/admin/users/:id/ban" do
	auth_denied unless get_current_user.admin?
	id = params[:id].to_i

	user = User.find_by_id id
	user.banned = true

	flash[:error] = "Banned user '#{user.name}'"

	redirect back
end

# Unban user
# @param [Integer] id
# @see User#banned=
get "/admin/users/:id/unban" do
	auth_denied unless get_current_user.admin?
	id = params[:id].to_i

	user = User.find_by_id id
	user.banned = false

	flash[:success] = "Unbanned user '#{user.name}'"

	redirect back
end

# Edit user credentials
# @param [Integer] id
get "/admin/users/:id/edit" do
	auth_denied unless get_current_user.admin?
	id = params[:id].to_i
	user = User.find_by_id id

	serve :"admin/users/edit", {user: user}
end

# Give role to user
# @param [Integer] user_id User id
# @param [Integer] role_id Role id
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

# Revoke role from user
# @param [Integer] user_id User id
# @param [Integer] role_id Role id
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

# Set users money
# @param [Integer] id
# @param [Float] money
# @see User#balance=
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

# Set users reputation score
# @param [Integer] id
# @param [Float] reputation
post "/admin/users/setreputation" do
	user = get_current_user
	auth_denied unless user.admin? 

	id = params[:user_id].to_i
	reputation = params[:reputation].to_f
	target = User.find_by_id(id)

	target.reputation = reputation

	flash[:success] = "Set users reputation to '#{reputation}'."

	redirect back
end

# ADMIN ROLE MANAGEMENT

# Role check for id
def role_check(id)
	no_go_away if ROLE_IDS.include? id
	auth_denied unless get_current_user.permitted? :roleman
end

# Create role
# @param [String] name 
# @param [String] color Hex color
# @param [Integer Bitmap] flags
post "/admin/roles" do
	user = get_current_user
	auth_denied unless user.permitted? :roleman

	name = params[:name]
	color = params[:color]
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

# Delete role
# @param [Integer] id
get "/admin/roles/:id/delete" do
	id = params[:id].to_i
	role_check id
	
	Role.delete "id = ?", id

	flash[:success] = "Removed role."
	redirect back
end

# Edit role form
# @param [Integer] id
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

# Very user flags for operation
def verify_flags(flags, userflags)
	# TODO: check if this actually works
	# should work in practise but who knows
	newflags = flags & userflags # only give flags that the user have (max)
	flash[:error] = "You are not allowed those flags!" if newflags != flags
	return newflags
end

# Update role
# @param [Integer] id
# @param [String] name New name
# @param [String] color New hex color
# @param [Integer Bitmap] flags 
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

# Create category
# @param [String] name 
# @param [String] color Hex color string
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

# Delete a category
# @param [Integer] id
get "/admin/categories/:id/delete" do
	id = params[:id].to_i
	user = get_current_user
	auth_denied unless user.permitted? :cateman
	
	Category.delete "id = ?", id

	flash[:success] = "Removed category."
	redirect back
end

# Edit category form
# @param [Integer] id
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

# Update category
# @param [Integer] id
# @param [String] name New name
# @param [String] color New hex color
post "/admin/categories/:id/update" do
	id = params[:id].to_i
	user = get_current_user
	auth_denied unless user.permitted? :cateman

	data = {
		name: params[:name],
		color: params[:color],
	}
	resp = Category.edit id, data

	flash[:success] = "Updated category."
	redirect "/admin/categories/#{id}/edit"
end

