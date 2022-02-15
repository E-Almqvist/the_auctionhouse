# User table model
class User < EntityModel 
	attr_reader :email, :name, :bio_text, :balance, :avatar_url, :reputation

	def initialize(user_info)
		super user_info
		@email = user_info["email"]
		@name = user_info["name"]
		@bio_text = user_info["bio_text"]
		@balance = user_info["balance"]
		@avatar_url = user_info["avatar_url"]
		@reputation = user_info["reputation"]
	end

	def self.get_avatar
		gravatar = Gravatar.src @email
		if gravatar then
			return gravatar
		else
			return @avatar_url
		end
	end

	# Find user by ID, returns multiple results if multiple IDs exist
	# (which wont happen since IDs are unique)
	def self.find_by_id(id)
		self.get("*", "id = ?", id)
	end

	# Find user by email, same as above but for emails.
	# Also unique
	def self.find_by_email(email)
		self.get("*", "email = ?", email)
	end

	def self.validate_register_creds(email, name, password, password_confirm)
		# Field check
		check_all_fields = email != "" && name != "" && password != "" && password_confirm != ""

		# Check email
		check_email_dupe = self.find_by_email(email).length <= 0
		check_email_valid = email.match(EMAIL_REGEX) != nil 

		# Name
		check_name_len = name.length >= MIN_NAME_LEN

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
			pw_hash = BCrypt::Password.create(password) 
			data = { # payload
				name: name,
				email: email,
				pw_hash: pw_hash
			}

			resp = self.insert(data) # insert into the db
			return check, resp
		else
			return check, errorstr
		end
	end


	# Log in user
	# Returns: success?, user info 
	def self.login(email, password)
		user_query = self.find_by_email email # get the user info

		return false, LOGIN_ERRORS[:fail] unless user_query.length >= 1  # Verify that a user was found

		user_info = user_query.first	
		pw_check = self.validate_password user_info["pw_hash"], password
		return false, LOGIN_ERRORS[:fail] unless pw_check # Verify password

		return true, user_info
	end
end
