require_relative "const"

COINS_PREFIX = "€"
COINS_SUFFIX = ""

AUTH_ERRORS = {
	needed: "Authentication is needed to perform that task! Please login!",
	denied: "You are not permitted to do that!"
}

REGISTER_ERRORS = {
	fields: "Please fill all of the fields",

	pass_len: "Password length must be at least #{MIN_PASSWORD_LEN}",
	pass_notequals: "Password mismatch",

	name_len: "Name length must be between #{MIN_NAME_LEN} and #{MAX_NAME_LEN} characters!",
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

AUCTION_ERRORS = {
	titlelen: "Title length must be between #{MIN_TITLE_LEN} and #{MAX_TITLE_LEN} characters!",
	initprice: "The initial price must be at least #{MIN_INIT_PRICE}!",
	deltatime: "Time span is too short! Must be at least one day!"
}

# Auction stuff
AH_BUYOUT_FACTOR = 1.8 
