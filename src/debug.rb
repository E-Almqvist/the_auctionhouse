module Console 
	def self.log(str, indent=4, *args)
		puts "#{str}"

		indentstr = " "*indent
		args.each do |s|
			puts "#{indentstr}:: #{s}"
		end
	end

	def self.debug(str, *args)
		if DEBUG then
			prefix = "[DEBUG] "
			print prefix.bold
			log(str, prefix.length, *args)
		end
	end

	def self.error(str, *args)
		prefix = "[ERROR] "
		print prefix.red.bold
		log(str.bold, prefix.length, *args)
	end
end
