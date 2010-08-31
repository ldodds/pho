require 'rubygems'
require 'json'
require 'pho'

# Use the demonstration store containing NASA space flight data
store = Pho::Store.new("http://api.talis.com/stores/space")

#Retrieve simple RDF description for this resource (Apollo 11 Launch) as RDF/XML
puts "Describe Apollo 11 Launch"
response = store.describe("http://purl.org/net/schemas/space/launch/1969-059")

# Dump to console
puts response.content

# SPARQL Query 
SPARQL = <<-EOL
PREFIX space: <http://purl.org/net/schemas/space/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>


DESCRIBE ?spacecraft WHERE {

     ?launch space:launched "1969-07-16"^^xsd:date.

  ?spacecraft space:launch ?launch.

}

EOL
puts "Describe spacecraft launched on 16th July 1969"
response = store.sparql_describe(SPARQL)
puts response.content

SPARQL_CONSTRUCT = <<-EOL

PREFIX space: <http://purl.org/net/schemas/space/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>

CONSTRUCT {
  ?spacecraft foaf:name ?name;
              space:agency ?agency;
              space:mass ?mass.          
}
WHERE {
  ?launch space:launched "1969-07-16"^^xsd:date.

  ?spacecraft space:launch ?launch;
              foaf:name ?name;
              space:agency ?agency;
              space:mass ?mass.          
}

EOL

puts "Get name, agency and mass for spacecraft launched on 16th July 1969"
response = store.sparql_construct(SPARQL_CONSTRUCT)
puts response.content

SPARQL_SELECT = <<-EOL
PREFIX space: <http://purl.org/net/schemas/space/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>

SELECT ?name
WHERE {

  ?launch space:launched "1969-07-16"^^xsd:date.

  ?spacecraft space:launch ?launch;
              foaf:name ?name.      
}

EOL

puts "Get name of spacecraft launched on 16th July 1969, as JSON"
response = store.sparql_construct(SPARQL_SELECT, "application/sparql-results+json")
json = JSON.parse( response.content )

json["results"]["bindings"].each do |b|
 
  puts b["name"]["value"]
  
end
