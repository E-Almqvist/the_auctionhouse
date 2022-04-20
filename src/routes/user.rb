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
