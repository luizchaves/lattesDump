files = `ls`.split "\n"
files.each {|f|
	next unless f.include? ".zip"
	`unzip #{f}; mv curriculo.xml #{f.sub(".zip", "")}.xml; rm #{f}`
}