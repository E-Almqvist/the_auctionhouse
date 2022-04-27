# Login page for the user
get "/login" do
	serve :"user/login", layout: :empty
end

# Register page for the user
get "/register" do
	serve :"user/register", layout: :empty
end

# Profile for user
# @param [Integer] id User id
get "/profile/:id" do
	id = params[:id].to_i
	userobj = User.find_by_id id

	if userobj then
		serve :"user/profile", {user: userobj}
	else
		raise Sinatra::NotFound
	end
end

# Profile user for logged in user
get "/profile" do 
	if is_logged_in then
		redirect "/profile/#{session[:userid]}"
	else
		redirect "/login"
	end
end

USER_REP_LIMIT ||= Hash.new(Hash.new(0))
# Add or remove users reputation score
# @param [Integer] id User id
# @param [String] type Either "plus" or "minus"
get "/user/rep/:id" do
	if !is_logged_in then
		session[:ret] = request.fullpath 
		session[:status] = 403
		flash[:error] = AUTH_ERRORS[:needed] 
		redirect "/login"
	end
	

	user = User.find_by_id params[:id].to_i
	if user then
		redirect "/profile/#{user.id}" unless params[:type]
		auth_denied "You can not give yourself reputation points!" if user.id == session[:userid]

		# Check the delta time and if we can ±rep again
		dt = Time.now.to_i - USER_REP_LIMIT[session[:userid]][user.id]
		ratelimit USER_REP_LIMIT_TIME - dt, "/profile/#{user.id}" unless dt > USER_REP_LIMIT_TIME

		# Update rate limit
		USER_REP_LIMIT[session[:userid]][user.id] = Time.now.to_i

		# Add to user rep
		delta = params[:type] == "plus" ? 1 : -1
		user.reputation += delta

		flash[:success] = "Gave '#{user.name.strip}' #{delta > 0 ? "+" : ""}#{delta} rep"
		redirect "/profile/#{user.id}"
	else
		raise Sinatra::NotFound
	end
end

# Logged in users settings
get "/settings" do
	serve :"user/settings"
end

# Register user
# @param [String] email
# @param [String] name
# @param [String] password
# @param [String] password_confirm
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

# Login user
# @param [String] email
# @param [String] password
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

# Logout current user
get "/logout" do 
	session.clear
	flash[:success] = "Successfully logged out!"
	redirect "/"
end

# Update user credentials
# @param [Integer] id (Only applied if logged in user is admin), otherwise it defaults to current session user
# @param [String] displayname New user name
# @param [String] bio_text New bio text
post "/user/update" do
	id = (get_current_user.admin? and params[:id]) ? params[:id].to_i : session[:userid]

	data = {
		name: params["displayname"].chomp,
		bio_text: params["bio"].chomp
	}

	if params[:image] then
		imgdata = params[:image][:tempfile] 
		save_image imgdata.read, File.dirname(__FILE__) + "/../public/avatars/#{id}.png" # save the image
		data[:avatar_url] = "/avatars/#{id}.png" # update image path
	end

	success, msg = User.find_by_id(id).update_creds data # update the user creds
	if not success then flash[:error] = msg end	

	flash[:success] = "Profile updated."
	redirect back
end
