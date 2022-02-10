# Register stuff
MIN_PASSWORD_LEN = 8
MIN_NAME_LEN = 2

EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

REGISTER_ERRORS = {
	pass_len: "Password length must be at least #{MIN_PASSWORD_LEN}",
	pass_notequals: "Password mismatch",

	name_len: "Name length must be at least #{MIN_NAME_LEN}",

	email_dupe: "Email already in use",
	email_fake: "Use a real email"
}

