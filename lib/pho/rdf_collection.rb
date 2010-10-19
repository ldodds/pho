module Pho
  
  module FileManagement

      # Provides a simple mechanism for managing a directory of RDF/XML documents
      # and uploading them to platform store.
      #
      # Allows a collection to be mirrored into the platform
      class RDFManager < AbstractFileManager
      
        RDF = "rdf".freeze
        TTL = "ttl".freeze
        NT = "nt".freeze
        
        ALL_RDF = [RDF, TTL, NT]
        
        def initialize(store, dir, rdf_suffixes=ALL_RDF, ok_suffix=OK, fail_suffix=FAIL)
          super(store, dir, ok_suffix, fail_suffix)
          @rdf_suffixes = rdf_suffixes
        end
                    
        #List files being managed
        def list(recursive=false)
            if recursive
              pattern = "**/*.\{#{ @rdf_suffixes.join(",") }\}"
            else
              pattern = "*.\{#{ @rdf_suffixes.join(",") }\}"
            end          
            return Dir.glob( File.join(@dir, pattern) )  
        end
         
        protected
    
        def store_file(file, filename)
          ext = File.extname(filename)
          if ext == ".ttl"
            response = @store.store_file(file, nil, "text/turtle")
          elsif ext == ".nt" 
            response = @store.store_file(file, nil, "text/turtle")
          else
            response = @store.store_file(file)
          end
                    
          if (response.status < 300 )
            File.open(get_ok_file_for(filename), "w") do |file|
              file.print( "OK" )            
            end
          else
            File.open(get_fail_file_for(filename), "w") do |file|
              YAML::dump(response, file)
            end            
          end      
        end  
        
             
      end
              
  end
  
  #Deprecated. Use Pho::FileManangement::RDFManager instead
  class RDFCollection < Pho::FileManagement::RDFManager
    #for backwards compatibility
  end
  
end  