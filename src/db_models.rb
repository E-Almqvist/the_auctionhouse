# User table model
class User < Table
	def initialize(db)
		super db, "User" 
	end

	# Find user by ID, returns multiple results if multiple IDs exist
	# (which wont happen since IDs are unique)
	def find_by_id(id)
		self.get("*", "id = ?", id)
	end

	# Find user by email, same as above but for emails.
	# Also unique
	def find_by_email(email)
		self.get("*", "email = ?", email)
	end

	private def validate_register_creds(email, name, password, password_confirm)
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

	# Register a new user
	# Returns: success?, data
	def register(email, name, password, password_confirm)
		check, errorstr = self.validate_register_creds(email, name, password, password_confirm)

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

	# Log in user
	# Returns: success?, auth token
	def login(email, password)
		user_query = self.find_by_email email # get the user info

		if user_query.length >= 1 then
			user_info = user_query.first	
		end
	end
end
