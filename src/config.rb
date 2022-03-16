require_relative "const"

AUTH_ERRORS = {
	needed: "Authentication is needed to perform that task! Please login!"
}

REGISTER_ERRORS = {
	fields: "Please fill all of the fields",

	pass_len: "Password length must be at least #{MIN_PASSWORD_LEN}",
	pass_notequals: "Password mismatch",

	name_len: "Name length must be between #{MIN_NAME_LEN} and #{MAX_NAME_LEN}",
	name_desc: "May only contain alphabetical characters and must be between #{MIN_NAME_LEN} and #{MAX_NAME_LEN} characters long",

	email_dupe: "Email is already in use",
	email_fake: "Please use a valid email address"
}

SETTINGS_ERRORS = {
	name_len: "Name length must be between #{MIN_NAME_LEN} and #{MAX_NAME_LEN} characters!",
	bio_len: "Biography length must be between #{MIN_BIO_LEN} and #{MAX_BIO_LEN} characters!"
}

# Login stuff
LOGIN_ERRORS = {
	fields: "Please fill all of the fields",
	fail: "Wrong password and/or email"
}

# Auction stuff
AH_BUYOUT_FACTOR = 1.8 
