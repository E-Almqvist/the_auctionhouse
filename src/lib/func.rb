def get_random_subtitle
	subtitles = File.readlines(File.dirname(__FILE__) + "/../misc/subtitles.txt")
	subtitles.sample.chomp
end

def is_logged_in
	session[:userid] != nil
end

def get_current_user 
	session[:userid] && User.find_by_id(session[:userid])
end

def format_time(seconds)
	result = []
	TIME_FORMATS.each do |sym, count|
		amount = seconds.to_i / count
		if amount > 0 then
			result << "#{amount}#{sym.to_s}"
			seconds -= count*amount
		end
	end
	result = result[0...2]
	return result.join ", "
end

# Serve templates
def serve(template, locals={}, layout: :layout)
	locals[:session_user] = get_current_user unless !is_logged_in

	# Serve the slim template
	status session[:status] if session[:status]
	session.delete :status
	slim(template, locals: locals, :layout => layout)
end

# Save image
def save_image imgdata, path
	image = Magick::Image.from_blob(imgdata).first
	image.format = "PNG"
	File.open(path, 'wb') do |f|
		image.resize_to_fill(AVATAR_SIZE, AVATAR_SIZE).write(f) 
	end
end
