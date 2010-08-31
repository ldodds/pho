require 'rubygems'
require 'pho'
require 'sinatra'

#SETUP
store = Pho::Store.new("http://api.talis.com/stores/space")
mime :rdf, "application/rdf+xml"

#ROUTES

#E.g. http://127.0.0.1:4567/?url=http://nasa.dataincubator.org/spacecraft/1969-059A
get "/*" do  
  sparql_client = store.sparql_client()
  resp = sparql_client.describe_uri(params[:url], "application/rdf+xml", :lcbd)
  
  if resp.status != 200
    halt resp.status, resp.message
  end
  content_type :rdf
  resp.contentend