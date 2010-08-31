require 'rubygems'
require 'pho'

query = <<-EOL
PREFIX space: <http://purl.org/net/schemas/space/>
SELECT ?s WHERE {
   ?s a space:Spacecraft.
}
LIMIT 10
EOL

sparql_client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/space/services/sparql")

uris = Pho::Sparql::SparqlHelper.selectValues(query, sparql_client)

uris.each do |uri|
  puts uri
end
