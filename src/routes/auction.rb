# Auction stuff
get "/auctions" do
	title = params[:title] and params[:title] != "" ? params[:title].strip : nil
	categories = params[:categories]
	categories.map! {|catid| catid.to_i} unless categories.nil?
	min_price = params[:min_price].to_f > 0 ? params[:min_price].to_f : nil
	max_price = params[:max_price].to_f > 0 ? params[:max_price].to_f : nil
	expired = params[:expired] == "on"

	auctions = Auction.search title, categories, min_price, max_price, expired
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
	images = params[:images] 

	# Min image count check
	if images.nil? or images.length < AH_MIN_IMAGES then
		flash[:error] = AUCTION_ERRORS[:imagecount]
		redirect "/auctions/new"
	end
	# 

	# Create the auction
	newid, resp = Auction.create user_id, title, description, init_price, delta_time

	if newid then
		# Save auction images 
		images.each_with_index do |img, i|
			Image.save img[:tempfile].read, newid, i 
		end

		# Apply categories to auction 
		category_choices = (params.select { |k, v| k.to_s.match(/^category-\d+/) }).map{ |k, v| v.to_i }
		category_choices.each do |catid|
			if Category.exists? catid then
				Auction_Category_relation.insert({auction_id: newid, category_id: catid})
			end
		end

		flash[:success] = "Auction posted!"
		redirect "/auctions/#{newid}"
	else
		flash[:error] = resp
		redirect "/auctions/new"
	end
end

get "/auctions/:id" do
	id = params[:id].to_i
	auction = Auction.find_by_id id

	if !auction.nil? then
		serve :"auction/view", {auction: auction}	
	else
		raise Sinatra::NotFound
	end
end

get "/auctions/:id/edit" do
	id = params[:id].to_i
	auction = Auction.find_by_id id

	if !auction.nil? then
		auth_denied "You can not edit expired auctions!" if auction.expired?
		auth_denied unless auction.user_id == session[:userid] or get_current_user.admin?

		flash[:success] = "Updated post."
		serve :"auction/edit", {auction: auction}	
	else
		raise Sinatra::NotFound
	end
end

get "/auctions/:id/delete" do
	id = params[:id].to_i
	auction = Auction.find_by_id id

	if !auction.nil? then
		auth_denied "You can not delete expired auctions!" if auction.expired?
		auth_denied unless auction.user_id == session[:userid] or get_current_user.admin?

		# Delete everything related in the db
		Auction.delete "id = ?", id
		Auction_Category_relation.delete "auction_id = ?", id
		Bid.delete "auction_id = ?", id 

		flash[:success] = "Removed post."

		redirect "/auctions"
	else
		raise Sinatra::NotFound
	end
end

post "/auctions/:id/update" do
	id = params[:id].to_i
	auction = Auction.find_by_id id

	if !auction.nil? then
		auth_denied "You can not edit expired auctions!" if auction.expired?
		auth_denied unless auction.user_id == session[:userid] or get_current_user.admin?

		new_title = params[:title].strip
		new_desc = params[:description].strip
		
		auction.edit new_title, new_desc

		redirect "/auctions/#{id}"
	else
		raise Sinatra::NotFound
	end
end

post "/auctions/:id/bids" do
	id = params[:id].to_i
	auction = Auction.find_by_id id

	amount = params[:amount].to_f
	message = params[:message]

	if !auction.nil? then
		success, resp = auction.place_bid(session[:userid], amount, message)
		if success then
			flash[:success] = "Placed bid."
		else
			flash[:error] = resp
		end
		redirect "/auctions/#{id}"
	else
		raise Sinatra::NotFound
	end
end
