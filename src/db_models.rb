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

	def avatar
		return @avatar_url
	end

	def role
		user_roles = roles
		if user_roles.length > 0 then
			role = user_roles.max_by { |role| role.flags }
			return role.name 
		end
		return ""
	end

	def roles
		User_Role_relation.get_user_roles @id
	end

	def rep_score
		return BAD_REP if @reputation < 0
		return GOOD_REP if @reputation > 0
		return NEUTRAL_REP 
	end

	def bio_html
		md_parser = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
		md_parser.render @bio_text
	end

	def reputation_text
		sign = @reputation > 0 ? "+" : ""	
		return "#{sign}#{@reputation}"
	end

	def reputation=(val)
		val = val.clamp MIN_REP, MAX_REP
		@reputation = val
		self.update({reputation: val}, "id = ?", @id)
	end

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

	# Find user by ID, returns a user object 
	def self.find_by_id(id)
		data = self.get("*", "id = ?", id).first
		data && User.new(data)
	end

	# Find user by email, same as above but for emails.
	def self.find_by_email(email)
		data = self.get("*", "email = ?", email).first
		data && User.new(data)
	end

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

	def self.validate_password(pw_hash, password)
		BCrypt::Password.new(pw_hash) == password
	end

	# Register a new user
	# Returns: success?, data
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
	# Returns: success?, user id 
	def self.login(email, password)
		user = self.find_by_email email # get the user info

		return false, LOGIN_ERRORS[:fail] unless user # Verify that the user exists 

		pw_check = self.validate_password(user.pw_hash, password)
		return false, LOGIN_ERRORS[:fail] unless pw_check # Verify password

		return true, user.id
	end

	# Check if user has permission
	# TODO: Make this work
	def self.permitted?(id, perm)
		user = self.find_by_id id
		roles = user.roles
		# check each role for flag
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

	# TODO: Check if role has specific flag
	def has_flag?(flag)
		# do bitwise ops	
	end

	def self.find_by_id(id)
		data = self.get("*", "id = ?", id).first
		data && Role.new(data)
	end

	def self.find_by_name(name)
		data = self.get("*", "name = ?", name).first
		data && Role.new(data)
	end

	def self.create(name, color="#ffffff", flags=0)
		data = {
			name: name,
			color: color,
			flags: flags
		}
		self.insert data
	end

	def self.edit(roleid, data)
		self.update data, "id = #{roleid}"
	end
end


class User_Role_relation < EntityModel
	def self.get_user_roles(user_id)
		roleids = self.get "role_id", "user_id = ?", user_id
		roles = roleids.map do |ent| 
			Role.find_by_id(ent["role_id"].to_i)
		end
	end
end


# Auction model
class Auction < EntityModel
	attr_reader :user_id, :title, :description, :init_price, :start_time, :end_time
	def initialize(data)
		super data
		@user_id = data["user_id"]
		@title = data["title"]
		@description = data["description"]
		@init_price = data["init_price"]
		@start_time = data["start_time"]
		@end_time = data["end_time"]
	end

	private def self.validate_ah(title, description, init_price, delta_time)
		return false, AUCTION_ERRORS[:titlelen] unless title.length.between?(MIN_TITLE_LEN, MAX_TITLE_LEN)
		return false, AUCTION_ERRORS[:initprice] unless init_price >= MIN_INIT_PRICE
		return false, AUCTION_ERRORS[:deltatime] unless delta_time >= MIN_DELTA_TIME
		return true, ""
	end

	def self.create(user_id, title, description, init_price, delta_time, categories) 
		# Remove invalid categories
		categories.select! do |id|
			self.exists? id
		end

		# Validate the input
		check, errorstr = self.validate_ah(title, description, init_price, delta_time)
		return errorstr unless check

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

	def self.compose_query_filters(title=nil, categories=nil, price_rng=nil, isopen=nil)
		querystr = "SELECT * FROM Auction "
		querystr += "WHERE " if title or categories or price_rng or time_left

		filters = []
		filters << "LIKE '%#{title}%'" if title
		filters << "price BETWEEN #{price_rng[0]} AND #{price_rng[1]}" if price_rng && price_rng.length == 2
		filters << "end_time > #{Time.now.to_i}" if !isopen.nil?

		querystr += filters.join " AND "
		return querystr
	end

	def self.search(title=nil, categories=nil, price_rng=nil, isopen=nil)
		q = self.compose_query_filters title, categories, price_rng, isopen	
		self.query q
	end
end


class Category < EntityModel
	attr_reader :name, :color
	def initialize(data)
		super data
		@name = data["name"]
		@color = data["color"]
	end

	def self.create(name, color)
		data = {
			name: name,
			color: color
		}
		self.insert(data)
	end
end


class Image < EntityModel
	attr_reader :auction_id, :image_order, :url
	def initialize(data)
		super data
		@auction_id = data["auction_id"]
		@image_order = data["image_order"]
		@url = data["url"]
	end
end


class Auction_Category_relation < EntityModel
	attr_reader :auction_id, :category_id
	def initialize(data)
		super data
		@auction_id = data["auction_id"]
		@category_id = data["category_id"]
	end

	def self.get_user_roles(user_id)
		roleids = self.get "role_id", "user_id = ?", user_id
		roles = roleids.map do |ent| 
			Role.find_by_id(ent["role_id"].to_i)
		end
	end
end

