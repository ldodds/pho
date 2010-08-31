module Pho
  
  #This module organizes the classes related to the Facet service
  module Facet
    
    #Captures the information about a specific term
    class Term
      attr_reader :hits
      attr_reader :search_uri
      attr_reader :value
      
      def initialize(hits, search_uri, value)
        @hits = hits
        @search_uri = search_uri
        @value = value
      end
      
    end
    
    #Captures the data returned in a facetted search 
    class Results
      
      #The query used to generate the facet results, as echoed in the response
      attr_reader :query
      
      #The fields used to generate the results
      attr_reader :fields
      
      #An array of facets
      attr_reader :facets
      
      def initialize(query, fields, facets=Hash.new)
        @query = query
        @fields = fields
        @facets = facets
      end
      
      #Convenience function to perform a facetted search against a store, returning a 
      #Results object parsed from the XML response
      #
      #store:: the store against which the query will be performed
      #query:: the search query
      #facets:: an ordered list of facets to be used
      #params:: additional params. See Store.facet for details. XML output is requested automatically
      def Results.read_from_store(store, query, facets, params=Hash.new)
        
        params["output"] = "xml"
        resp = store.facet(query, facets, params)    
            
        if resp.status != 200
          raise "Unable to do facetted search. Response code was #{resp.status}"
        end
        
        return parse(resp.content)
        
      end

      def Results.parse(data)
        doc = REXML::Document.new(data)
        root = doc.root
        head = root.elements[1]

        query = ""
        fields = ""
        queryEl = head.get_elements("query")[0]
        if queryEl != nil
          query = queryEl.text
        end
        fieldsEl = head.get_elements("fields")[0]
        if fieldsEl != nil
          fields = fieldsEl.text
        end

        results = Results.new(query, fields)
        
        fields = root.get_elements("fields")[0]
        if fields == nil
          raise "No fields in document!"
        end
        
        fields.get_elements("field").each do |field|
          field_name = field.attribute("name").value
          results.facets[field_name] = Array.new
          
          field.get_elements("term").each do |term|
            term = Term.new(term.attribute("number").value.to_i, 
              term.attribute("search-uri").value, 
              term.text() )
              
            results.facets[field_name] << term
          end
          
        end
        
        return results          
      end
            
    end
    
  end
end