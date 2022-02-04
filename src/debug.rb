def log(str, *args)
	puts "#{str}"
	args.each do |s|
		puts " :: #{s}"
	end
end

def debug(str, *args)
	if DEBUG then
		print "DEBUG :: "
		log "#{str}", *args
	end
end

