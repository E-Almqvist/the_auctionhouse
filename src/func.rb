def get_random_subtitle
	subtitles = File.readlines "misc/subtitles.txt"
	subtitles.sample.chomp
end

def init_info(*infos)
	g = Hash.new ""
	info = g.merge(*infos)
	return info
end

def user 
	session[:userid] && User.find_by_id(session[:userid])
end

# Serve templates
def serve(template, info={})
	# Insert the error info (if it exists)
	error_info = session[:error_msg] != nil ? {error_msg: session[:error_msg]} : {}
	session[:error_msg] = nil

	# Serve the slim template
	slim(template, locals: {info: init_info(info, error_info), user: user})
end
