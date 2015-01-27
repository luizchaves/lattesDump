#  Dados demográficos
# 	- Nome ok
# 	- Área de atuação ok
# 	- Sexo (podemos tentar)
# 	- Raça (se estiver disponível no lattes)
# 	- Modalidade de bolsa (se houver) ok
# 	- Endereço profissional ok
# 	- Maior Titulação ok
# 	- ?


# - Local e Data de Eventos Relevantes

# 	-  Nascimento (cidade, país, estado)
# 	-  Graduação ()
# 	-  Especialização
# 	-  Mestrado
# 	-  Doutorado
# 	-  Pós-doutorado
# 	-  Ínício de vínculo(s) profissional(is) (um pesquisador pode mudar de emprego :-) )
# 	-  Data da última atualização do lattes
# 	-  ?

# SQL

require 'thread/pool'
require 'nokogiri'
require 'open-uri'
require 'json'

$result = []
$count = 0
$total = 0
$course = []

def extract(xpath)
	value = $xmldoc.xpath(xpath)
	if value.length < 1
		""
	else
		value[0].value
	end
end

def extractInfo(file)
	puts "%%%%%%%%"+file
	xmlfile = File.new("lattes/#{file}")
	$xmldoc = Nokogiri::XML(xmlfile)

	research = {}
	#id
	id = $xmldoc.xpath("//CURRICULO-VITAE/@NUMERO-IDENTIFICADOR")[0]
	if id != nil
		research[:id] = id.value
	else
		research[:id] = ""
		puts ">>>>"+file
	end

	# Atualização
	research[:updated] = $xmldoc.xpath("//CURRICULO-VITAE/@DATA-ATUALIZACAO")[0].value

	# NOME
	research[:name] = $xmldoc.xpath("//DADOS-GERAIS/@NOME-COMPLETO")[0].value

	# Nascimento
	research[:birth] = {}	
	research[:birth][:location] = {}	
	research[:birth][:location][:city] = $xmldoc.xpath("//DADOS-GERAIS/@CIDADE-NASCIMENTO")[0].value
	research[:birth][:location][:uf] = $xmldoc.xpath("//DADOS-GERAIS/@UF-NASCIMENTO")[0].value
	research[:birth][:location][:county] = $xmldoc.xpath("//DADOS-GERAIS/@PAIS-DE-NASCIMENTO")[0].value

	# Modalidade de bolsa??

	# Área de atuação
	research[:knowledge] = []
	formation = $xmldoc.xpath("//AREA-DE-ATUACAO")
	formation.each{|f|
		knowledge = {}
		knowledge[:"NOME-GRANDE-AREA-DO-CONHECIMENTO"] = f.xpath("//@NOME-GRANDE-AREA-DO-CONHECIMENTO")[0].value
		knowledge[:"NOME-DA-AREA-DO-CONHECIMENTO"] = f.xpath("//@NOME-DA-AREA-DO-CONHECIMENTO")[0].value
		knowledge[:"NOME-DA-SUB-AREA-DO-CONHECIMENTO"] = f.xpath("//@NOME-DA-SUB-AREA-DO-CONHECIMENTO")[0].value
		knowledge[:"NOME-DA-ESPECIALIDADE"] = f.xpath("//@NOME-DA-ESPECIALIDADE")[0].value
		research[:knowledge] << knowledge
	}
	# PROFISSÃO
	# course ??? orientação?
	city = $xmldoc.xpath("//ENDERECO-PROFISSIONAL/@CIDADE")[0].value
	uf = $xmldoc.xpath("//ENDERECO-PROFISSIONAL/@UF")[0].value
	country = $xmldoc.xpath("//ENDERECO-PROFISSIONAL/@PAIS")[0].value
	university = $xmldoc.xpath("//ENDERECO-PROFISSIONAL/@NOME-INSTITUICAO-EMPRESA")[0].value
	orgao = $xmldoc.xpath("//ENDERECO-PROFISSIONAL/@NOME-ORGAO")[0].value
	research[:work] = {
		location: {
			city: city,
			uf: uf,
			country: country
		},
		university: university,
		orgao: orgao
	}

	# FORMAÇÃO
	# city, uf ???
	research[:formation] = []
	formation = $xmldoc.xpath("//FORMACAO-ACADEMICA-TITULACAO").children
	formation.each{|f|
		university = extract("//FORMACAO-ACADEMICA-TITULACAO/#{f.name}/@NOME-INSTITUICAO")
		universityCode = extract("//FORMACAO-ACADEMICA-TITULACAO/#{f.name}/@CODIGO-INSTITUICAO")
		country = extract("//INFORMACAO-ADICIONAL-INSTITUICAO[@CODIGO-INSTITUICAO='#{universityCode}']/@NOME-PAIS-INSTITUICAO")
		course = extract("//FORMACAO-ACADEMICA-TITULACAO/#{f.name}/@NOME-CURSO")
		year = extract("//FORMACAO-ACADEMICA-TITULACAO/#{f.name}/@ANO-DE-CONCLUSAO")
		title = extract("//FORMACAO-ACADEMICA-TITULACAO/#{f.name}/@TITULO-DA-DISSERTACAO-TESE")
		$total += 1 
		if course == "" && country == ""
			$count += 1 
			$course << f.name
			# if f.name == "DOUTORADO"
			# 	puts file
			# end
		end
		puts f.name
		puts "#"
		puts course
		puts university
		puts country
		puts year
		puts title
		research[:formation] << {
			formation: f.name.to_sym,
			location: {
				country: country
			},
			university: university,
			course: course,
			title: title,
			year: year
		}
	}

	$result << research
end

files = `ls lattes`.split "\n"
lattesPool = Thread.pool(1)
# files[0..900].each{|f|
files.each{|f|
	lattesPool.process do
		next unless f.include? ".xml"
		begin
			extractInfo f
		rescue
			puts $!, $@
		end
	end
}
lattesPool.shutdown
puts $count
puts $total
puts ($count/$total.to_f)*100
puts $course.inspect

# puts JSON.pretty_generate($result)