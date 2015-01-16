files = `ls`
files =  files.split "\n"
result = File.open("doutores-id16.dat", "w")
files.each{|f|
	next unless f.include? ".html"
	content = ''
	open(f, "r:ISO-8859-1:UTF-8") do |io|
		content = io.read
	end
	id = ''
	begin
		id = content.match /\d{16}/
	rescue
		puts "\n #{f}"
	end
	# print " [#{id}] "
	print "."
	result.write("#{id}\n")
}