require 'nokogiri'
require 'pg'
require 'date'

conn = PG.connect(host: '192.168.56.101', dbname: 'curriculos', user: 'postgres', password: 'postgres')
conn.prepare('statement1', 'insert into lattes (id, xml) values ($1, $2)')

files = `ls lattes`
files.split("\n")[0..20].each_with_index{|file, index|
	xml = ""
	open("lattes/"+file, "r:iso-8859-1:utf-8") do |io|
	  xml = io.read
	end
	doc = Nokogiri::XML(xml)
	conn.exec_prepared('statement1', [(index), xml])
	print " #{index} "
}

