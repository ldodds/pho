module Pho
  
  #Resource Hashes
  #
  #Dependent on the redland ruby bindings  
  module ResourceHash

    #TODO wrap Redland exceptions. Parser/Serializer contruction as well as parsing errors
    
    begin
      require 'rdf/redland'
    rescue LoadError
      $stderr.puts "WARNING: Unable to load redland-ruby bindings. Changeset support unavailable"
    end
    
    #Class for converting to and from resource hashes 
    class Converter
      
      #Parse JSON structured according to the RDF-in-JSON specification into 
      #a Ruby resource hash. Simply invokes the JSON parser.
      #
      # json:: valid RDF-in-JSON
      def Converter.parse_json(json)
        return JSON.parse(json)
      end
      
      #Parse a string containing RDF/XML into a resource hash
      #
      # rdfxml: a String containing RDF/XML
      def Converter.parse_rdfxml(rdfxml, base_uri)
        return Converter.parse(rdfxml, base_uri, "rdfxml")
      end

      #Parse a string containing N-Triples into a resource hash
      #
      # ntriples:: a String containing N-Triples
      def Converter.parse_ntriples(ntriples, base_uri)
        return Converter.parse(ntriples, base_uri, "ntriples")
      end

      #Parse a string containing Turtle into a resource hash
      #
      # ntriples:: a String containing Turtle
      def Converter.parse_turtle(turtle, base_uri)
        return Converter.parse(turtle, base_uri, "turtle")
      end
                              
      #Convert specified format into a ResourceHash
      #
      # format:: one of rdfxml, ntriples, turtle
      # data:: String containing the data to be parsed
      # base_uri:: base uri of the data
      def Converter.parse(data, base_uri, format="rdfxml")
        model = Redland::Model.new()
        case format
          when "rdfxml" then mime="application/rdf+xml"
          when "json" then mime="application/json"
          else mime=""     
        end
        
        parser = Redland::Parser.new(format, mime)
        parser.parse_string_into_model(model, data, base_uri)
        serializer = Redland::Serializer.new( "json", "application/json" )
        json = serializer.model_to_string(Redland::Uri.new(base_uri), model)
        return Converter.parse_json( json )        
      end

      #Serialize a resource hash as RDF-in-JSON
      #
      # hash:: the resource hash to serialize      
      def Converter.serialize_json(hash)
          return JSON.dump(hash)  
      end
            
      
    end
            
  end  
end