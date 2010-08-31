module Pho

  #Module containing general RDF utilities and classes
  #
  #Dependent on the redland ruby bindings
  module RDF
    
    begin
      require 'rdf/redland'
    rescue LoadError
      $stderr.puts "WARNING: Unable to load redland-ruby bindings. Some RDF utils will be unavailable"
    end
    
    #General RDF parsing utilities.
    #
    #Currently a convenience wrapper around the Redland Ruby bindings 
    class Parser
      
      #Parse a file containing ntriples into RDF/XML. Returns a string
      #
      # file:: File object
      # base_uri:: optional base uri to be used when parsing. If not set, then uris are resolved
      # relative to the File
      def Parser.parse_ntriples(file, base_uri=nil)
        model = Redland::Model.new()
        parser = Redland::Parser.new("ntriples", "")
        uri = "file:#{file.path}"
        base_uri = uri unless base_uri
        parser.parse_into_model(model, uri, base_uri)
        serializer = Redland::Serializer.new( "rdfxml", "application/rdf+xml" )
        data = serializer.model_to_string(Redland::Uri.new(base_uri), model)
        return data                        
      end
      
      #Parse a string containing ntriples into RDF/XML. Returns a string
      #
      # string:: the string containing the data
      # base_uri:: base uri for parsing the data
      def Parser.parse_ntriples_from_string(string, base_uri)
        model = Redland::Model.new()
        parser = Redland::Parser.new("ntriples", "")
        parser.parse_string_into_model(model, string, Redland::Uri.new(base_uri))
        serializer = Redland::Serializer.new( "rdfxml", "application/rdf+xml" )
        data = serializer.model_to_string(Redland::Uri.new(base_uri), model)
        return data                                
      end

      #Convenience method to parse an ntriples file and store it a Platform store
      #
      # file:: the file to parse
      # store:: the store to receive the data
      # base_uri:: base uri against which the data is parsed
      # graph_name:: uri of graph in store
      # TODO: can now be submitted as turtle
      def Parser.store_ntriples(file, store, base_uri=nil, graph_name=nil)
         data = Parser.parse_ntriples(file, base_uri)
         return store.store_data(data, graph_name)       
      end

      #Convenience method to parse an ntriples string and store it a Platform store
      #
      # string:: the data to parse
      # store:: the store to receive the data
      # base_uri:: base uri against which the data is parsed
      # graph_name:: uri of graph in store
      # TODO: can now be submitted as turtle      
      def Parser.store_ntriples_from_string(string, store, base_uri, graph_name=nil)
         data = Parser.parse_ntriples_from_string(string, base_uri)
         return store.store_data(data, graph_name)       
      end
      
    end

  end

end