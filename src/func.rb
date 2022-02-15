def get_random_subtitle
	subtitles = File.readlines "misc/subtitles.txt"
	subtitles.sample.chomp
end

def init_info(info={})
	g = Hash.new ""
	info = g.merge(info)
	return info
end

def serve(template, info={})
	slim( template, locals: {info: init_info(info)} )
end
