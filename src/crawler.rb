require 'mechanize'
require 'open-uri'
require 'thread/pool'
require 'zip'

class Crawler

	# updated PG

	def initialize(data)
		f = File.read(data)
		@lattes_ids = f.split "\n"
	end

	def scrapy
		`rm temp/*`
		lattesPool = Thread.pool(10)
		@lattes_ids.each{|id|
			next if File.exist?("lattes/#{id}.zip") || File.exist?("lattes/#{id}.xml")
			lattesPool.process do
				(0..10).to_a.each{
					getLattes(id)
					break unless File.read("#{id}.zip").include? "DOCTYPE"
					`rm #{id}.zip temp/#{id}.png temp/#{id}.txt`
				}
				puts "Lattes #{id}"
			end
		}
		lattesPool.shutdown
	end

	def getLattes(id)
		agent = Mechanize.new
		# TODO try reopen url
		url = "http://buscatextual.cnpq.br/buscatextual/sevletcaptcha?idcnpq=#{id}"
		page  = agent.get url
		page.save "temp/#{id}.png"
		result = checkCaptcha id
		url = "http://buscatextual.cnpq.br/buscatextual/download.do?metodo=enviar&idcnpq=#{id}&palavra=#{result}"
		page  = agent.get url
		filename = "#{id}.zip"
		page.save filename
		unzip_file (filename, "lattes", filename.sub(".zip", ".xml"))
	end

	def checkCaptcha(id)
		result = ''
		(0..10).to_a.each{
			result = `tesseract temp/#{id}.png temp/#{id}; cat temp/#{id}.txt; rm temp/#{id}.png temp/#{id}.txt`
			result = result.upcase
			break if result.strip != "" && result.strip  =~ /^[A-Z0-9]*$/
		}
		result
	end

	def unzip_file (file, destination, filename)
	  Zip::ZipFile.open(file) { |zip_file|
	   zip_file.each { |f|
	     f_path=File.join(destination, filename)
	     FileUtils.mkdir_p(File.dirname(f_path))
	     zip_file.extract(f, f_path) unless File.exist?(f_path)
	   }
	  }
	end

end

begin
	data = ARGV[0]
	data ||= 'data/doutores.dat'
	c = Crawler.new data

	puts "\n\n===>Gerando os XML do Lattes"
	start_time = Time.now
	
	c.scrapy

	time_diff = Time.now - start_time
	time_diff = Time.at(time_diff.to_i.abs).utc.strftime "%H:%M:%S"
	puts "Tempo de execução \n#{time_diff}"
	lattesLength = `ls -1 lattes | wc -l`
	puts "Exitem #{lattesLength} currículos"
	puts "\n===>Finalizando o crawler"
rescue
	puts $!, $@
end