class User < Table
	def initialize(db)
		super db, "User" 
	end

	# Find user by ID, returns multiple results if multiple IDs exist
	# (which wont happen since IDs are unique)
	def find_by_id(id)
		self.get("*", "id = #{id}")
	end

	# Find user by email, same as above but for emails.
	# Also unique
	def find_by_email(email)
		self.get("*", "email = #{email}")
	end

	# Register a new user
	# Returns: success?, data
	def register(email, name, password, password_confirm)
		if( self.find_by_email(email).length > 0 ) then
			# Email taken
			return false, "Email already in use!"
		else
			if( password == password_confirm ) then
				pw_hash = BCrypt::Password.create(password) 
				data = { # payload
					name: name,
					email: email,
					pw_hash: pw_hash
				}

				resp = self.insert(@name, data) # insert into the db
				return true, resp
			else
				return false, "Password mismatch!"
			end
		end
	end
end
