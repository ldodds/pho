require 'yaml'

#TODO put together proper test suite for this
module Pho
  
  #Simple mechanism for managing etags
  class Etags
  
    attr_reader :file, :saved
    
    def initialize(file = nil)
      @file = file
      @saved = true
      @tags = Hash.new
      if @file != nil
          @tags = YAML::load(@file)[0]
      end
    end
    
    def save(other=nil)

      if (other != nil)
        other.write( @tags.to_yaml() )
        return
      else
        if (!saved && @file != nil )
            @file.write( @tags.to_yaml() )
            @file.close           
        end        
      end
                        
    end
    
    def add(uri, tag)     
      if (uri != nil && tag != nil)
        @tags[uri] = tag
        @saved = false        
      end
    end  
    
    def add_from_response(uri, response)
      add(uri, response.header["ETag"][0])
    end
    
    def get(uri)
      return @tags[uri]
    end
    
    def has_tag?(uri)
      return @tags.has_key?(uri)
    end
    
  end  
  
end