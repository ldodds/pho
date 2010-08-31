module Pho

  #TODO blank nodes
  
  #Module providing code for manipulating resource hashes structured according 
  #to the RDF in JSON spec
  module ResourceHash
    
    #Class providing set algebra methods over triple hashes
    class SetAlgebra
      
      #Accepts two triple hashes, expressed as RDF-in-JSON and returns a new
      #Ruby data structure that constitutes the different between the two graphs
      #
      #i.e. the return value will be a hash containing the triples that are in the 
      #first graph but which are not present in the second.
      #
      # first:: the first graph
      # second:: the second graph.
      def SetAlgebra.minus(first, second)
        
        difference = Hash.new        
        first.each do |uri,properties|          
          if second.has_key?(uri)           
            properties.each do |predicate,value|              
              if second[uri].has_key?(predicate)                
                #second hash has same uri and predicate, so check value arrays                
                second_value = second[uri][predicate]
                value.each do |val|
                  
                  if !object_in_array?(second_value, val)

                    difference[uri] ||= Hash.new
                    difference[uri][predicate] ||= Array.new
                    difference[uri][predicate] << val                      
                  end
                end
                 
              else                
                #uri is in second, but not this property and value
                difference[uri] ||= Hash.new
                difference[uri][predicate] = value                
              end              
            end
          else
            #uri not in second, so pass all straight-through
            difference[uri] = properties            
          end
          
        end
        
        return difference
        
      end
      
      #Is there an object in the specified array, that matches the provided description
      def SetAlgebra.object_in_array?(array, val)
        array.each do |entry|

          if entry["type"] == val["type"] 
             if entry["value"] == val["value"]

               if entry["type"] == "literal"
                 if entry["datatype"] == val["datatype"] && 
                    entry["lang"] = val["lang"]
                    return true
                 end                     
               end
               return true   
             end
            
          end
        end
        return false
      end
    end
    
  end
  
end  
