module Pho
  
  #Captures the details of a weighted field from a QueryProfile
  class FieldWeighting
    
    #The uri of the field weighting
    attr_reader :uri
    
    #The name of the field being weighted
    attr_reader :name
    
    #The weighting applied to the field
    attr_reader :weight
    
    def initialize(uri, name, weight)
      @uri = uri
      @name = name
      @weight = weight
    end
    
    #Convert this object into an RDF representation. Generates a simple rdf:Description, optionally including namespaces
    #ns:: include namespace declarations   
    def to_rdf(ns=true)
      rdf = "<rdf:Description " 
      if ns
        rdf << " xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:frm=\"#{Pho::Namespaces::FRAME}\" xmlns:bf=\"#{Pho::Namespaces::CONFIG}\" "        
      end 
      rdf << " rdf:about=\"#{@uri}\">"
      rdf << " <frm:name>#{@name}</frm:name>"      
      rdf << " <bf:weight>#{@weight}</bf:weight>"      
      rdf << "</rdf:Description>"
      return rdf  
    end    
    
  end
  
  
  #Models the QueryProfile configuration associated with a Platform store
  #
  #Class methods exist to read a QueryProfile from a store, providing some convenience 
  #over the basic Store methods.
  class QueryProfile

    #Label associated with the resource in the Platform config
    attr_reader :label
    
    #URI for this resource
    attr_reader :uri
    
    #The list of field weightings
    attr_reader :field_weights
    
    def QueryProfile.read_from_store(store)
      resp = store.get_query_profile(Pho::ACCEPT_JSON)        
      if resp.status != 200
        raise "Unable to read Query Profile from store. Response code was #{resp.status}"
      end

      qp_uri = store.build_uri("/config/queryprofiles/1")
      
      json = JSON.parse( resp.content )

      labels = json[qp_uri]["http:\/\/www.w3.org\/2000\/01\/rdf-schema#label"]
      if labels != nil && labels.length > 0
        label = labels[0]["value"]
      else
        label = "query profile"
      end
      qp = QueryProfile.new(qp_uri, label)
      
      field_weights = json[qp_uri]["http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#fieldWeight"]
      field_weights.each { |uri|
        property = json[uri["value"]]
        name = property["http:\/\/schemas.talis.com\/2006\/frame\/schema#name"][0]["value"]
        weight = property["http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#weight"][0]["value"]
        qp << FieldWeighting.new(uri["value"], name, weight)
      }
      
      return qp        
      
    end
    
    #Create a FieldWeighting object suitable for adding to this store. Will ensure that the 
    #name of the propery is valid according to the Platform naming rules
    #
    #store:: the store that the weighting is to be created for
    #name:: name of the field to be weighted
    #weight:: the weighting of the field 
    def QueryProfile.create_weighting(store, name, weight)
      if !name.match(/^[a-zA-Z][a-zA-Z0-9]*$/)
        raise "Name does not conform to regular expression: ^[a-zA-Z][a-zA-Z0-9]*$"
      end        
  
      weight_uri = store.build_uri("/config/queryprofiles/1##{name}")
      return FieldWeighting.new(weight_uri, name, weight)
      
    end
    
    def initialize(uri, label, field_weights=Array.new)
      @uri = uri
      @label = label
      @field_weights = field_weights
    end
        
    def <<(weight)
        @field_weights << weight    
    end

    #Retrieve a FieldWeighing by name
    def get_by_name(name)
      return @field_weights.detect { |field| field.name == name }  
    end
    
    #Remove a FieldWeighting by name
    def remove_by_name(name)
      fw = get_by_name(name)
      if (fw != nil)
        return remove(fw)
      end   
    end

    #Remove a FieldWeighting from the collection
    def remove(fw)
      return @field_weights.delete(fw)
    end    

    #Remove all field weights
    def remove_all()
      @field_weights = Array.new
    end
    
    #Is there a field weighting for a property with this name?
    def mapped_name?(name)
      return get_by_name(name) != nil
    end
                    
    #Dump this object to an RDF/XML representation suitable for submitting to the Platform
    def to_rdf
      rdf = "<rdf:RDF xmlns:frm=\"#{Pho::Namespaces::FRAME}\" "
      rdf << " xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" "
      rdf << " xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\" "
      rdf << " xmlns:bf=\"#{Pho::Namespaces::CONFIG}\" > " 
   
      rdf << " <rdf:Description rdf:about=\"#{@uri}\"> "
      
      rdf << " <rdf:type rdf:resource=\"#{Pho::Namespaces::CONFIG}QueryProfile\"/> "
      rdf << " <rdfs:label>#{@label}</rdfs:label> "
      
      @field_weights.each do |property|
        rdf << " <bf:fieldWeight rdf:resource=\"#{property.uri}\"/> "
      end
                  
      rdf << " </rdf:Description>"
      
      @field_weights.each do |property|
        rdf << property.to_rdf(false)
      end
            
      rdf << "</rdf:RDF>"
    end 

    #Upload an RDF/XML presentation of this object to the provided Platform Store
    def upload(store)
        return store.put_query_profile(self.to_rdf)  
    end 

        
    private
    def QueryProfile.get_suffix(uri)
      candidate_suffix = uri.split("/").last
      if candidate_suffix.index("#") != -1
        return candidate_suffix.split("#").last
      end
      return candidate_suffix
    end
        
  end
  
  
end