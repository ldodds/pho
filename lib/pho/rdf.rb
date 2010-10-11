module Pho

  #Module containing general RDF utilities and classes
  #
  #Dependent on the redland ruby bindings
  module RDF
    
    #General RDF parsing utilities.
    #
    #Currently a convenience wrapper around the Redland Ruby bindings 
    class Parser
      
      #Convenience method to parse an ntriples file and store it a Platform store
      #
      # file:: the file to parse
      # store:: the store to receive the data
      # graph_name:: uri of graph in store
      def Parser.store_ntriples(file, store, graph_name=nil)
         data = File.new(file, "r").read()
         return store.store_data(data, graph_name, "text/plain")       
      end

      #Convenience method to parse an ntriples string and store it a Platform store
      #
      # string:: the data to parse
      # store:: the store to receive the data
      # graph_name:: uri of graph in store
      def Parser.store_ntriples_from_string(string, store, graph_name=nil)
         return store.store_data(string, graph_name, "text/plain")       
      end
      
    end

  end

end