def get_random_subtitle
	subtitles = File.readlines "misc/subtitles.txt"
	subtitles.sample.chomp
end

def init_data(data={})
	g = Hash.new ""
	g.merge(data)
end

