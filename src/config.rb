# Register stuff
MIN_PASSWORD_LEN = 8
MIN_NAME_LEN = 2

EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

REGISTER_ERRORS = {
	fields: "Please fill all of the fields",

	pass_len: "Password length must be at least #{MIN_PASSWORD_LEN}",
	pass_notequals: "Password mismatch",

	name_len: "Name length must be at least #{MIN_NAME_LEN}",

	email_dupe: "Email is already in use",
	email_fake: "Please use a valid email address"
}

LOGIN_ERRORS = {
	fields: "Please fill all of the fields",
	fail: "Wrong password and/or email"
}
