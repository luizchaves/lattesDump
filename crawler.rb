require 'mechanize'
require 'open-uri'
require 'thread/pool'

class Crawler

	def initialize
		@agent = Mechanize.new
		ARGV[0] = 'data/doutores.dat' if ARGV[0] == ''
		f = File.read("#{ARGV[0]}")
		@lattes_ids = f.split "\n"
	end

	def scrapy
		`rm temp/*`
		lattesPool = Thread.pool(10)
		@lattes_ids.each{|id|
			next if File.exist?("lattes/#{id}.zip")
			lattesPool.process do
				# TODO try reopen url
				url = "http://buscatextual.cnpq.br/buscatextual/sevletcaptcha?idcnpq=#{id}"
				page  = @agent.get url
				page.save "temp/#{id}.png"
				result = `tesseract temp/#{id}.png temp/#{id}; cat temp/#{id}.txt; rm temp/#{id}.png temp/#{id}.txt`
				url = "http://buscatextual.cnpq.br/buscatextual/download.do?metodo=enviar&idcnpq=#{id}&palavra=#{result}"
				page  = @agent.get url
				page.save "#{id}.zip"
				puts "Lattes #{id}"
				# `unzip lattes/#{id}.zip ; rm lattes/#{id}.zip; mv lattes/curriculo.xml lattes/#{id}.xml`
			end
		}
		lattesPool.shutdown
		`mv *.zip lattes`
	end

end

c = Crawler.new
begin
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