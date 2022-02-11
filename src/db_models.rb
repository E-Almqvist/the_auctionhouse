class User < Table
	def initialize(db)
		super db, "User" 
	end

	# Find user by ID, returns multiple results if multiple IDs exist
	# (which wont happen since IDs are unique)
	def find_by_id(id)
		resp = self.get("*", "id = ?", id)
	end

	# Find user by email, same as above but for emails.
	# Also unique
	def find_by_email(email)
		resp = self.get("*", "email = ?", email)
	end

	private def validate_credentials(email, name, password, password_confirm)
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
		# TODO: refactor 
		if not check_all_fields then
			return false, REGISTER_ERRORS[:fields]
		elsif not check_email_dupe then
			return false, REGISTER_ERRORS[:email_dupe]
		elsif not check_email_valid then
			return false, REGISTER_ERRORS[:email_fake]
		elsif not check_name_len then
			return false, REGISTER_ERRORS[:name_len]
		elsif not check_pass_equals then
			return false, REGISTER_ERRORS[:pass_notequals]
		elsif not check_pass_len then
			return false, REGISTER_ERRORS[:pass_len]
		else
			return true, ""
		end
	end

	# Register a new user
	# Returns: success?, data
	# TODO: input checks & ERRORS!
	def register(email, name, password, password_confirm)
		check, errorstr = self.validate_credentials(email, name, password, password_confirm)

		if( check ) then
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
end
