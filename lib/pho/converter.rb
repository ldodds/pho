module Pho
  
  #Resource Hashes
  #
  #Dependent on the redland ruby bindings  
  module ResourceHash
        
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
      def Converter.parse_rdfxml(rdfxml)
        return Converter.parse(rdfxml, :rdfxml)
      end

      #Parse a string containing N-Triples into a resource hash
      #
      # ntriples:: a String containing N-Triples
      def Converter.parse_ntriples(ntriples)
        return Converter.parse(ntriples, :ntriples)
      end

      #Parse a string containing Turtle into a resource hash
      #
      # ntriples:: a String containing Turtle
      def Converter.parse_turtle(turtle)
        return Converter.parse(turtle, :turtle)
      end
                              
      #Convert specified format into a ResourceHash
      #
      # format:: one of :rdfxml, :ntriples, :turtle
      # data:: String containing the data to be parsed
      def Converter.parse(data, format=:rdfxml)
        graph = RDF::Graph.new()
        io = StringIO.new( data )
        
        RDF::Reader.for(format).new(io) do |reader|
          reader.each_statement do |statement|
            graph << statement
          end
        end
        
        json = StringIO.new()
        
        RDF::Writer.for(:json).new(json) do |writer|
          writer << graph
        end
        
        return Converter.parse_json( json.string )        
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