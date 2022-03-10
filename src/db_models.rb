# User table model
class User < EntityModel 
	attr_reader :email, :name, :bio_text, :balance, :avatar_url, :pw_hash, :reputation

	def initialize(data)
		super data
		@email = data["email"]
		@name = data["name"]
		@bio_text = data["bio_text"]
		@balance = data["balance"]
		@avatar_url = data["avatar_url"]
		@reputation = data["reputation"]
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
end


class Role < EntityModel
	attr_reader :name, :color, :flags
	def initialize(data)
		super data
		@name = data["name"]
		@color = data["color"]
		@flags = data["flags"]
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


class Auction < EntityModel
	def initialize(data)
		super data
		@title = data["title"]
		@description = data["description"]
		@start_time = data["start_time"]
		@end_time = data["end_time"]
	end
end
