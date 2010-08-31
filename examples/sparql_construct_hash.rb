require 'rubygems'
require 'pho'

query = <<-EOL
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

sparql_client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/space/services/sparql")

data = Pho::Sparql::SparqlHelper.constructToResourceHash(query, sparql_client)

puts data.inspect()
