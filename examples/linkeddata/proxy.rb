# This example illustrates how to create a publish Linked Data using the Talis Platform, Pho and Sinatra 
#
# You need to make sure that you have some data available in your platform store under the URIs at which 
# the application is running.
#
# E.g:
# http://www.example.org/id/a/b/c
# http://127.0.0.1:4567/id/a/b/c
#
# The script takes care of directing to equivalent uris under /data (e.g /data/a/b/c) and then delivers
# a view of the data generated by the Platform.
#
# This is sufficient for publishing linked data views of RDF. Useful extensions would be to support content 
# negotiation.
require 'rubygems'
require 'pho'
require 'sinatra'

mime :rdf, "application/rdf+xml"

store = Pho::Store.new("http://api.talis.com/stores/ldodds-dev1")
sparql_client = store.sparql_client()

helpers do
  
  def datauri(request)
    path = request.fullpath.gsub("/id", "/data")
    if request.port != 80
      url = "http://#{request.host}:#{request.port}#{path}"
    else  
      url = "http://#{request.host}#{path}"
    end
    return url      end
end

#Redirect from this url to the /data one at which we're going to actually
#serve the data, after first checking that the URI exists.  
get "/id/*" do    url = datauri(request)
  puts url
  begin 
    #if !Pho::Sparql::SparqlHelper.exists(url, sparql_client)
    #  status 400
    #else
      status 303
      response['Location'] = url
      halt
    #end
  rescue
    status 500
    $!.to_s    
  end
     end

#Does the work of retrieving the RDF data from the Platform.
get "/data/*" do
  
  url = datauri(request)

  begin
    sparql_client = store.sparql_client()
    resp = sparql_client.describe_uri(url, "application/rdf+xml", :lcbd)
  
    if resp.status != 200
      status resp.status
    end
  
    content_type :rdf
    resp.content
    
  rescue
    status 500
    $!.to_s
  end
    end