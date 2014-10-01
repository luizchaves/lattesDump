require 'mechanize'
require 'open-uri'
require 'thread/pool'

class Crawler

	def scrapy
		agent = Mechanize.new
		f = File.read('data/doutores.dat')
		@lattes_ids = f.split "\n"
		lattesPool = Thread.pool(10)
		@lattes_ids[1..10].each{|id|
			lattesPool.process do
				# TODO try reopen url
				url = "http://buscatextual.cnpq.br/buscatextual/sevletcaptcha?id=#{id}"
				page  = agent.get url
				page.save "temp/#{id}.png"
				result = `tesseract temp/#{id}.png temp/#{id}; cat temp/#{id}.txt; rm temp/#{id}.png temp/#{id}.txt`
				url = "http://buscatextual.cnpq.br/buscatextual/download.do?metodo=enviar&id=#{id}&palavra=#{result}"
				page  = agent.get url
				page.save "lattes/#{id}.zip"
				# `unzip lattes/#{id}.zip ; rm lattes/#{id}.zip; mv lattes/curriculo.xml lattes/#{id}.xml`
				p "Lattes #{id}"
			end
		}
		lattesPool.shutdown
	end

end

c = Crawler.new
begin
	c.scrapy
rescue
	puts $!, $@
end