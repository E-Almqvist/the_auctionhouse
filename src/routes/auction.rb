# Auction stuff
get "/auctions" do
	title = params[:title]
	#categories = (params[:categories].split ",").map {|id| id.to_i} 
	#price_rng = (params[:price_rng].split "-").map {|p| p.to_i}
	isopen = params[:isopen]

	auctions = Auction.search title #, categories, price_rng, isopen
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

	# Create the auction
	newid, resp = Auction.create user_id, title, description, init_price, delta_time

	if newid then
		# Save auction images 
		images = params[:images] 
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
	auction_obj = Auction.find_by_id id

	if !auction_obj.nil? then
		serve :"auction/view", {auction: auction_obj}	
	else
		raise Sinatra::NotFound
	end
end

post "/auctions/:id/bids" do
	id = params[:id].to_i
	auction_obj = Auction.find_by_id id

	amount = params[:amount].to_f
	message = params[:message]

	if !auction_obj.nil? then
		success, resp = auction_obj.place_bid( session[:userid], amount, message)
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
