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

	# Register a new user
	# Returns: success?, data
	# TODO: input checks & ERRORS!
	def register(email, name, password, password_confirm)
		check_email = self.find_by_email(email)
		if( check_email.length > 0 ) then
			# Email taken
			return false, {error_msg: "Email already in use!"}
		else
			if( password == password_confirm ) then
				pw_hash = BCrypt::Password.create(password) 
				data = { # payload
					name: name,
					email: email,
					pw_hash: pw_hash
				}

				resp = self.insert(data) # insert into the db
				return true, {resp: resp}
			else
				return false, {error_msg: "Password mismatch!"}
			end
		end
	end
end
