# User model
class User < EntityModel 
	attr_reader :email, :name, :bio_text, :balance, :avatar_url, :pw_hash, :reputation

	def initialize(data)
		super data
		@email = data["email"]
		@name = data["name"]
		@bio_text = data["bio_text"]
		@balance = data["balance"].to_f
		@avatar_url = data["avatar_url"]
		@reputation = data["reputation"].to_i
		@pw_hash = data["pw_hash"]
	end

	# Get user avatar url
	def avatar
		return @avatar_url
	end

	# Get all of the users auctions
	def auctions
		Auction.get_all "user_id = ?", @id
	end

	# Get the most dominant roles name
	# @return [String] Role name
	def role
		return Role.find_by_id( ROLES[:admin][:id] ).name if self.admin?

		user_roles = self.roles
		if user_roles.length > 0 then
			role = user_roles.max_by { |role| role.flags }
			return role.name 
		end
		return ""
	end

	# Get all of the users role ids
	# @see User#roles
	# @return [Array<Integer>] Array of all the primary keys for the roles
	def role_ids
		User_Role_relation.get_user_roles_ids @id
	end

	# Get all of the users role ids
	# @see User#role_ids
	# @return [Array<Role>] Array of all the users role objects
	def roles
		User_Role_relation.get_user_roles @id
	end

	# Gets the reputation enum for the user
	# @return [Integer] Reputation score enum
	def rep_score
		return BAD_REP if @reputation < 0
		return GOOD_REP if @reputation > 0
		return NEUTRAL_REP 
	end

	# Reputation text for the user
	# @return [String] Reputation score string
	def reputation_text
		sign = @reputation > 0 ? "+" : ""	
		return "#{sign}#{@reputation}"
	end

	# Sets the users reputation to given value
	# @see EntityModel#update
	# @param [Integer] val The value
	def reputation=(val)
		val = val.clamp MIN_REP, MAX_REP
		@reputation = val
		User.update({reputation: val}, "id = ?", @id)
	end

	# Sets the users balance
	# @see EntityModel#update
	# @param [Float] val The value
	def balance=(val)
		val = val >= 0 ? val : 0
		@balance = val
		User.update({balance: val}, "id = ?", @id)
	end

	# Updates the user credentials
	# @see EntityModel#update
	def update_creds(data)
		# Validate input
		return false, SETTINGS_ERRORS[:name_len] unless data[:name].length.between?(MIN_NAME_LEN, MAX_NAME_LEN)
		return false, SETTINGS_ERRORS[:bio_len] unless data[:bio_text].length.between?(MIN_BIO_LEN, MAX_BIO_LEN)

		# Filter unchanged data
		data.keys.each do |k|
			data.delete(k) if @data[k.to_s] == data[k]
		end
		User.update(data, "id = ?", @id) unless data.length < 1
		return true, nil
	end

	# Find user by email, same as EntityModel#find_by_id but for emails.
	# @see EntityModel#query
	# @see EntityModel#find_by_id
	def self.find_by_email(email)
		data = self.get("*", "email = ?", email).first
		data && User.new(data)
	end

	# Verify user registration credentials
	# @param [String] email The email
	# @param [String] name The users name
	# @param [String] password Password
	# @param [String] password_confirm Password confirmation
	# @return [Boolean] Failed?
	# @return [String] Error message
	def self.validate_register_creds(email, name, password, password_confirm)
		# Field check
		check_all_fields = email != "" && name != "" && password != "" && password_confirm != ""

		# Check email
		check_email_dupe = self.find_by_email(email) == nil
		check_email_valid = email.match(EMAIL_REGEX) != nil 

		# Name
		check_name_len = name.length.between?(MIN_NAME_LEN, MAX_NAME_LEN)

		# Password
		check_pass_equals = password == password_confirm
		check_pass_len = password.length >= MIN_PASSWORD_LEN 

		# This code is really ugly
		return false, REGISTER_ERRORS[:fields] unless check_all_fields
		return false, REGISTER_ERRORS[:email_dupe] unless check_email_dupe
		return false, REGISTER_ERRORS[:email_fake] unless check_email_valid
		return false, REGISTER_ERRORS[:name_len] unless check_name_len
		return false, REGISTER_ERRORS[:pass_notequals] unless check_pass_equals
		return false, REGISTER_ERRORS[:pass_len] unless check_pass_len
		return true, ""
	end

	# Verify password
	# @param [String] pw_hash Digested password 
	# @param [String] password Password 
	# @return [Boolean] Passwords are equal 
	def self.validate_password(pw_hash, password)
		BCrypt::Password.new(pw_hash) == password
	end

	# Register a new user
	# @param [String] email Email
	# @param [String] name Users name
	# @param [String] password Password 
	# @param [String] password_confirm Password confirm
	# @return [Boolean] success?
	# @return [String] Error string
	def self.register(email, name, password, password_confirm)
		check, errorstr = self.validate_register_creds(email, name, password, password_confirm)

		if check then
			pw_hash = BCrypt::Password.create password
			data = { # payload
				name: name,
				email: email,
				pw_hash: pw_hash
			}

			resp = self.insert data # insert into the db
			return check, resp
		else
			return check, errorstr
		end
	end

	# Log in user
	# @param [String] email Users email
	# @param [String] password Users password
	# @return [Boolean] Success? 
	# @return [Integer] Users id 
	def self.login(email, password)
		user = self.find_by_email email # get the user info

		return false, LOGIN_ERRORS[:fail] unless user # Verify that the user exists 

		pw_check = self.validate_password(user.pw_hash, password)
		return false, LOGIN_ERRORS[:fail] unless pw_check # Verify password

		return true, user.id
	end

	# Get a users combined flags
	# @return [Integer Bitmap] A bitmap of all the flags
	def flags
		flags = 0
		self.roles.each do |role|
			if role.is_a? Role then
				flags |= role.flags
			end
		end
		return flags
	end

	# Check if user is an admin
	# @return [Boolean]
	def admin?
		return self.flags[1] == 1
	end

	# Check if user is permitted with certian flag
	# @param [Symbol] flag Flag symbol
	# @return [Boolean] true or false depending whether the user has those flags
	def permitted?(flag, *other_flags)
		return true if self.admin?

		flag_mask = PERM_LEVELS[flag]
		if other_flags then
			other_flags.each {|f| flag_mask |= PERM_LEVELS[f]}
		end

		return self.flags & flag_mask == flag_mask
	end

	# Check if user is banned
	# @return [Boolean]
	def banned?
		return self.flags[ PERM_LEVELS.keys.index(:banned) ] == 1
	end

	# Set users "banned" status
	# @return [String] Error/info string
	def banned=(b)
		if b then
			# Add the "banned" role
			resp = User_Role_relation.give_role(@id, ROLES[:banned][:id])
		else
			# Remove the "banned" role
			resp = User_Role_relation.revoke_role(@id, ROLES[:banned][:id])
		end
	end
end

# Role model
class Role < EntityModel
	attr_reader :name, :color, :flags
	def initialize(data)
		super data
		@name = data["name"]
		@color = data["color"]
		@flags = data["flags"]
	end

	# Check if role has a flag
	def has_flag?(flag, *other_flags)
		flag_mask = PERM_LEVELS[flag]

		# Add other flags
		if other_flags then
			other_flags.each do |f|
				flag_mask += PERM_LEVELS[f]
			end
		end

		return @flags & flag_mask == flag_mask # f AND m = m => flags exists
	end

	# Find role by name
	# @see EntityModel#find_by_id
	# @return [Role] Role object
	def self.find_by_name(name)
		data = self.get("*", "name = ?", name).first
		data && Role.new(data)
	end

	# Create a role
	# @param [String] name Role name
	# @param [Color String] color Role color in hex
	# @param [Integer Bitmap] flags Flags bitmap
	def self.create(name, color="#ffffff", flags=0)
		return false, REGISTER_ERRORS[:name_len] unless name.length.between?(MIN_NAME_LEN, MAX_NAME_LEN)

		data = {
			name: name,
			color: color,
			flags: flags
		}
		self.insert data
	end
end


class User_Role_relation < EntityModel
	def self.init_table
		super
		
		# Add the "first user" to the admin role
		search = self.get("role_id", "user_id=1") or []
		if search.length <= 0 then
			q = "INSERT INTO #{self.name} (user_id, role_id) VALUES (?, ?)"
			self.query(q, 1, 1)
		end
	end

	# Give role to user
	# @param [Integer] user_id User id
	# @param [Integer] role_id Role id
	# @see EntityModel#insert
	def self.give_role(user_id, role_id)
		user = User.find_by_id user_id

		if not user.role_ids.include?(role_id) then
			data = {
				role_id: role_id,
				user_id: user_id
			}
			self.insert data
		end
	end

	# Revoke role from user
	# @param [Integer] user_id User id
	# @param [Integer] role_id Role id
	# @see EntityModel#delete
	def self.revoke_role(user_id, role_id)
		user = User.find_by_id user_id

		if user.role_ids.include?(role_id) then
			self.delete "role_id = ? AND user_id = ?", role_id, user_id
		end
	end

	# Gets users role ids in an array
	# @see User_Role_relation#get_user_roles
	# @param [Integer] user_id User id
	# @return [Array<Integer>] Role ids
	def self.get_user_roles_ids(user_id)
		ids = self.get "role_id", "user_id = ?", user_id
		ids.map! do |ent|
			ent["role_id"].to_i
		end
	end
	
	# Gets users roles in an array
	# @see User_Role_relation#get_user_roles_ids
	# @param [Integer] user_id User id
	# @return [Array<Role>] Roles 
	def self.get_user_roles(user_id)
		roleids = self.get_user_roles_ids user_id
		roles = roleids.map do |id| 
			Role.find_by_id(id)
		end
	end
end


# Auction model
class Auction < EntityModel
	attr_reader :user_id, :title, :description, :init_price, :start_time, :end_time
	def initialize(data)
		super data
		@user_id = data["user_id"].to_i
		@title = data["title"]
		@description = data["description"]
		@init_price = data["price"].to_f
		@start_time = data["start_time"].to_i
		@end_time = data["end_time"].to_i
	end

	# Validates auction params
	# @return [Boolean] Success?
	# @return [String] Error string
	def self.validate_ah(title, description, init_price, delta_time)
		return false, AUCTION_ERRORS[:titlelen] unless title.length.between?(MIN_TITLE_LEN, MAX_TITLE_LEN)
		return false, AUCTION_ERRORS[:initprice] unless init_price >= MIN_INIT_PRICE
		return false, AUCTION_ERRORS[:deltatime] unless delta_time >= MIN_DELTA_TIME
		return false, AUCTION_ERRORS[:desclen] unless description.length.between?(MIN_DESC_LEN, MAX_DESC_LEN)
		return true, ""
	end

	# Creates an auction post
	# @param [Integer] user_id Posters id
	# @param [String] title 
	# @param [String] description
	# @param [Float] init_price Initial price offering 
	# @param [Integer] delta_time Auction duration in seconds
	# @see EntityModel#insert
	# @see Auction#validate_ah
	def self.create(user_id, title, description, init_price, delta_time) 
		# Validate the input
		check, errorstr = self.validate_ah(title, description, init_price, delta_time)
		return check, errorstr unless check

		# Get current UNIX time
		start_time = Time.now.to_i 
		end_time = start_time + delta_time 

		# Prep the payload
		data = {
			user_id: user_id,
			title: title,
			description: description,
			price: init_price,
			start_time: start_time,
			end_time: end_time
		}

		self.insert data
	end

	# Composes SQL query filters for the auction searching function
	# @return [string] Query filters
	def self.compose_query_filters(title=nil, categories=nil, min_price=nil, max_price=nil, expired=nil)
		querystr = "SELECT * FROM Auction WHERE "
		filters = []

		# Title filter
		filters << "title LIKE '%#{title}%'" if title and title.length != 0

		# Price filters
		if min_price and max_price then
			filters << "price BETWEEN #{min_price} AND #{max_price}" 
		elsif min_price then
			filters << "price >= #{min_price}" 
		elsif max_price then
			filters << "price <= #{max_price}" 
		end

		# Time filter
		filters << "end_time #{ expired == true ? "<" : ">" } #{Time.now.to_i}" 

		# Categories filter
		if categories then
			ah_ids = []
			categories.each do |catid|
				if ah_ids == [] then
					ah_ids = Auction_Category_relation.category_auction_ids(catid) # first time then include all
				else
					ah_ids |= Auction_Category_relation.category_auction_ids(catid) # do union for all ids (prevent dupes)
				end
			end
			filters << "id IN (#{ah_ids.join(", ")})" # check if the auction id is any of the ids calculated above
		end

		querystr += filters.join " AND "
		return querystr
	end

	# Searches the database for related auctions that fit the params
	# @param [String] title
	# @param [Array<Integer>] categories Category ids
	# @param [Integer] min_price
	# @param [Integer] max_price
	# @param [Boolean] expired
	# @return [Array<Auction>] Array of auctions
	def self.search(title=nil, categories=nil, min_price=nil, max_price=nil, expired=nil)
		q = self.compose_query_filters title, categories, min_price, max_price, expired	
		data = self.query(q) 
		data.map! {|dat| self.new(dat)}
	end

	# Checks if expired
	# @return [Boolean]
	def self.expired?(id)
		ah = self.find_by_id id
		ah && ah.expired?
	end

	# Edits auction title and description
	# @see EntityModel#update
	def edit(title, description)
		return false, AUCTION_ERRORS[:titlelen] unless title.length.between?(MIN_TITLE_LEN, MAX_TITLE_LEN)
		return false, AUCTION_ERRORS[:desclen] unless description.length.between?(MIN_DESC_LEN, MAX_DESC_LEN)

		data = {
			title: title,
			description: description
		}
		Auction.update data, "id = ?", @id
	end

	# Deletes the auction
	def delete 
		FileUtils.rm_rf("./public/auctions/#{@id}") # delete all images

		Auction.delete "id = ?", @id # delete the actual post entry
		Auction_Category_relation.delete "auction_id = ?", @id
		Image.delete "auction_id = ?", @id
		Bid.delete "auction_id = ?", @id 
	end

	# Auction poster object
	# @return [User]
	def poster
		User.find_by_id @user_id
	end

	# Auction images
	# @return [Array<Image>]
	def images
		Image.get_relation @id
	end

	# Auctions category ids
	# @see Auction#categories
	# @return [Array<Integer>] Array of ids
	def category_ids
		data = Auction_Category_relation.get "category_id", "auction_id = ?", @id
		data && data.map! {|category| category["category_id"].to_i}
	end

	# Auctions categories
	# @see Auction#category_ids
	# @return [Array<Category>] Array of categories
	def categories
		data = self.category_ids
		data && data.map! { |catid| Category.find_by_id catid}
	end

	# @see Auction#expired?
	def expired?
		Time.now.to_i > @end_time
	end

	# Time left
	# @return [Integer] Time left in seconds
	def time_left
		@end_time - Time.now.to_i
	end

	# Time left 
	# @return [String] Formatted time string
	def time_left_s
		left = self.time_left
		return format_time(left)
	end

	# Get auctions bids
	# @return [Array<Bid>] Bids
	def bids
		Bid.get_bids(@id)
	end

	# Place bid on auction
	# @param [Integer] uid Bidders id (user)
	# @param [Float] amount 
	# @param [String] message
	# @see Bid#place 
	def place_bid(uid, amount, message)
		Bid.place(@id, uid, amount, message)
	end

	# Get the dominant bid object
	# @return [Bid]
	def max_bid 
		max_bid = self.bids.max_by {|bid| bid.amount}
	end

	# Current bid
	def current_bid
		mbid = self.max_bid
		if mbid != nil then
			return mbid.amount.to_f
		else
			return @init_price.to_f
		end
	end

	# Minimum required new bid 
	def min_new_bid
		max_bid = self.max_bid
		amount = max_bid.nil? ? @init_price : max_bid.amount 
		return amount * AH_BIDS_FACTOR 
	end
end

# Auction bids
class Bid < EntityModel
	attr_reader :amount, :auction_id, :user_id, :message
	def initialize(data)
		super data
		@amount = data["amount"].to_f
		@auction_id = data["auction_id"].to_i
		@user_id = data["user_id"].to_i
		@message = data["message"]
	end

	# Gets auctions bids
	def self.get_bids(ahid)
		data = self.get "*", "auction_id = ?", ahid
		data && data.map! {|dat| self.new(dat)}
	end

	# Get users bids
	def self.get_user_bids(uid)
		data = self.get "*", "user_id = ?", uid
		data && data.map! {|dat| self.new(dat)}
	end

	# Users bids active amount
	def self.get_user_active_amount(uid)
		bids = self.get_user_bids uid
		return bids.sum {|bid| bid.amount}
	end

	# How much more the users new bid is from their last bid
	# @return [Float] 
	def self.get_delta_amount(ahid, uid, amount)
		data = self.get "*", "auction_id = ? AND user_id = ?", ahid, uid
		if data and data.length > 0 then 
			data.map! {|dat| self.new(dat)}
			max_bid = data.max_by {|bid| bid.amount}
			return amount - max_bid.amount
		else
			return amount
		end
	end

	# Validate a new bid
	# @return [Boolean] Success?
	# @return [String] Error message
	def self.validate_bid(ahid, uid, amount, message)
		ah = Auction.find_by_id ahid
		return false, "Invalid auction" unless ah.is_a? Auction
		return false, AUCTION_ERRORS[:expired] unless not ah.expired?
		return false, AUCTION_ERRORS[:ownerbid] unless uid != ah.user_id
		return false, AUCTION_ERRORS[:cantafford] unless User.find_by_id(uid).balance - amount >= 0
		return false, AUCTION_ERRORS[:bidamount] unless amount >= ah.min_new_bid
		return true, ""
	end

	# Place a new bid
	# @param [Integer] ahid Auction id
	# @param [Integer] uid User id
	# @param [Float] amount
	# @param [String] message
	# @see EntityModel#insert
	# @see Bid#validate_bid 
	# @return [Boolean] Success?
	# @return [String, Hash] Error message or insert query data
	def self.place(ahid, uid, amount, message)
		check, resp = self.validate_bid(ahid, uid, amount, message)
		if check then
			# Deduct delta amount from balance
			delta_amount = self.get_delta_amount(ahid, uid, amount)
			user = User.find_by_id uid
			user.balance -= delta_amount

			payload = {
				auction_id: ahid,
				user_id: uid,
				amount: amount,
				message: message
			}
			resp = self.insert(payload)
		end
		return check, resp
	end
end


class Category < EntityModel
	attr_reader :name, :color
	def initialize(data)
		super data
		@name = data["name"]
		@color = data["color"]
	end

	# Create a new category
	# @see EntityModel#insert
	def self.create(name, color)
		data = {
			name: name,
			color: color
		}
		self.insert(data)
	end
end

class Auction_Category_relation < EntityModel
	attr_reader :auction_id, :category_id
	def initialize(data)
		super data
		@auction_id = data["auction_id"]
		@category_id = data["category_id"]
	end

	# Get all auctions that have the specified category
	# @return [Array<Integer>] Auction ids
	def self.category_auction_ids(catid)
		ids = self.get "auction_id", "category_id = ?", catid	
		ids && ids.map! {|id| id["auction_id"].to_i}
	end
end


class Image < EntityModel
	attr_reader :auction_id, :image_order, :url
	def initialize(data)
		super data
		@auction_id = data["auction_id"]
		@image_order = data["image_order"].to_i
		@url = data["url"]
	end

	# Save an image to the DB and disk
	# @param [Image Data] imgdata
	# @param [Integer] ah_id Auction id
	# @param [Integer] order Image order on the auction page
	def self.save(imgdata, ah_id, order)
		FileUtils.mkdir_p File.dirname(__FILE__) + "/../public/auctions/#{ah_id}"

		data = {
			auction_id: ah_id,
			image_order: order,
			url: "/auctions/#{ah_id}/#{order}.png"
		}
		newid, resp = self.insert data	

		if newid then
			image = Magick::Image.from_blob(imgdata).first
			image.format = "PNG"
			path = File.dirname(__FILE__) + "/../public/auctions/#{ah_id}/#{order}.png"
			File.open(path, 'wb') do |f|
				image.write(f) { self.quality = 50 }
			end
		end
	end

	# Gets the auction image relation
	# @return [Array<Image>] Auction images
	def self.get_relation(ah_id)
		imgs = self.get "*", "auction_id = ?", ah_id
		imgs.map! do |img|
			self.new(img)
		end
		return imgs
	end
end

