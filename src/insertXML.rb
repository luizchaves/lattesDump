require 'nokogiri'
require 'pg'
require 'date'

ids_lattes = File.read('lattes-trans-ok.dat')
ids_lattes = ids_lattes.split "\n"
ids = {}
ids_lattes.each {|v|
	v = v.split(', ')
	ids[v[1]] = v[0]
}

conn = PG.connect(host: 'localhost', dbname: 'lattes', user: 'postgres', password: 'xmllattes')
conn.prepare('statement1', 'insert into lattes (id16, id10, updated, xml) values ($1, $2, $3, $4)')

files = `ls lattes`
files.split("\n").each{|file|
	id16 = file.sub(".xml", "")
	xml = ""
	open("lattes-pqs/"+file, "r:iso-8859-1:utf-8") do |io|
	  xml = io.read
	end
	doc = Nokogiri::XML(xml)
	date = doc.xpath "//CURRICULO-VITAE/@DATA-ATUALIZACAO"
	date = Date.strptime(date.to_s,"%d%m%Y")
	updated = date.strftime("%Y-%m-%d")
	# puts id16, ids[id16], updated, xml
	conn.exec_prepared('statement1', [id16, ids[id16], updated, xml])

	# TODO remove file.xml, pool thread, time(start - end)

	print '.'

}

