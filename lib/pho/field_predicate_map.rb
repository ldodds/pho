module Pho

  #Declares URI constants for the various text analyzers supported by the Talis Platform
  #
  #Analyzers are configured to operate on specific DataTypePropertys using the FieldPredicateMap
  class Analyzers
 
    #A standard English analyzer and the default if no analyzer is specified. Words are split on punctuation characters, removing the punctuation. Words containing a dot are not split. Words containing both hyphens and numbers are not split. Email addresses and hostnames are not split. Stop words are removed. Searches on fields with this type of analyzer are case insensitive.
    #
    #The following words are considered to be stop words and will not be indexed: a, an, and, are, as, at, be, but, by, for, if, in, into, is, it, no, not, of, on, or, such, that, the, their, then, there, these, they, this, to, was, will, with  
    STANDARD = "http://schemas.talis.com/2007/bigfoot/analyzers#standard-en".freeze
    
    #A standard Greek language analyzer. Words are split on punctuation characters, removing the punctuation. Words containing a dot are not split. Words containing both hyphens and numbers are not split. Email addresses and hostnames are not split. Stop words are removed. Searches on fields with this type of analyzer are case insensitive. 
    GREEK = "http://schemas.talis.com/2007/bigfoot/analyzers#standard-el".freeze
    
    #A standard German language analyzer. Words are split on punctuation characters, removing the punctuation. Words containing a dot are not split. Words containing both hyphens and numbers are not split. Email addresses and hostnames are not split. Stop words are removed and any remaining words are stemmed. Searches on fields with this type of analyzer are case insensitive.
    
    #The following words are considered to be stop words and will not be indexed: einer, eine, eines, einem, einen, der, die, das, dass, daß, du, er, sie, es, was, wer, wie, wir, und, oder, ohne, mit, am, im, in, aus, auf, ist, sein, war, wird, ihr, ihre, ihres, als, für, von, mit, dich, dir, mich, mir, mein, sein, kein, durch, wegen, wird 
    GERMAN = "http://schemas.talis.com/2007/bigfoot/analyzers#standard-de".freeze
        
    #A standard French language analyzer. Words are split on punctuation characters, removing the punctuation. Words containing a dot are not split. Words containing both hyphens and numbers are not split. Email addresses and hostnames are not split. Stop words are removed and any remaining words are stemmed. Searches on fields with this type of analyzer are case insensitive.
    #
    #The following words are considered to be stop words and will not be indexed: a, afin, ai, ainsi, après, attendu, au, aujourd, auquel, aussi, autre, autres, aux, auxquelles, auxquels, avait, avant, avec, avoir, c, car, ce, ceci, cela, celle, celles, celui, cependant, certain, certaine, certaines, certains, ces, cet, cette, ceux, chez, ci, combien, comme, comment, concernant, contre, d, dans, de, debout, dedans, dehors, delà, depuis, derrière, des, désormais, desquelles, desquels, dessous, dessus, devant, devers, devra, divers, diverse, diverses, doit, donc, dont, du, duquel, durant, dès, elle, elles, en, entre, environ, est, et, etc, etre, eu, eux, excepté, hormis, hors, hélas, hui, il, ils, j, je, jusqu, jusque, l, la, laquelle, le, lequel, les, lesquelles, lesquels, leur, leurs, lorsque, lui, là, ma, mais, malgré, me, merci, mes, mien, mienne, miennes, miens, moi, moins, mon, moyennant, même, mêmes, n, ne, ni, non, nos, notre, nous, néanmoins, nôtre, nôtres, on, ont, ou, outre, où, par, parmi, partant, pas, passé, pendant, plein, plus, plusieurs, pour, pourquoi, proche, près, puisque, qu, quand, que, quel, quelle, quelles, quels, qui, quoi, quoique, revoici, revoilà, s, sa, sans, sauf, se, selon, seront, ses, si, sien, sienne, siennes, siens, sinon, soi, soit, son, sont, sous, suivant, sur, ta, te, tes, tien, tienne, tiennes, tiens, toi, ton, tous, tout, toute, toutes, tu, un, une, va, vers, voici, voilà, vos, votre, vous, vu, vôtre, vôtres, y, à, ça, ès, été, être, ô. 
    FRENCH = "http://schemas.talis.com/2007/bigfoot/analyzers#standard-fr".freeze
    
    #A standard CJK language analyzer. 
    CJK = "http://schemas.talis.com/2007/bigfoot/analyzers#standard-cjk".freeze
    
    #A standard Dutch language analyzer. Words are split on punctuation characters, removing the punctuation. Words containing a dot are not split. Words containing both hyphens and numbers are not split. Email addresses and hostnames are not split. Stop words are removed. Searches on fields with this type of analyzer are case sensitive.
    
    #The following words are considered to be stop words and will not be indexed: de, en, van, ik, te, dat, die, in, een, hij, het, niet, zijn, is, was, op, aan, met, als, voor, had, er, maar, om, hem, dan, zou, of, wat, mijn, men, dit, zo, door, over, ze, zich, bij, ook, tot, je, mij, uit, der, daar, haar, naar, heb, hoe, heeft, hebben, deze, u, want, nog, zal, me, zij, nu, ge, geen, omdat, iets, worden, toch, al, waren, veel, meer, doen, toen, moet, ben, zonder, kan, hun, dus, alles, onder, ja, eens, hier, wie, werd, altijd, doch, wordt, wezen, kunnen, ons, zelf, tegen, na, reeds, wil, kon, niets, uw, iemand, geweest, andere 
    DUTCH = "http://schemas.talis.com/2007/bigfoot/analyzers#standard-nl".freeze
    
    CHINESE = "http://schemas.talis.com/2007/bigfoot/analyzers#standard-cn".freeze
    
    #This analyzer does not split the field at all. The entire value of the field is indexed as a single token. 
    KEYWORD = "http://schemas.talis.com/2007/bigfoot/analyzers#keyword".freeze
    
    #English analyzer without stop words. This is identical to the standard English analyzer but all words are indexed. 
    NO_STOP_WORD_STANDARD = "http://schemas.talis.com/2007/bigfoot/analyzers#nostop-en".freeze
    
    #English analyzer without stop words and with accent support. This is identical to the standard English analyzer but all words are indexed plus any accented characters in the ISO Latin 1 character set are replaced by their unaccented equivalent
    #See API documentation at http://n2.talis.com/wiki/Field_Predicate_Map for details of replacements
    NORMALISE_STANDARD = "http://schemas.talis.com/2007/bigfoot/analyzers#norm-en".freeze

    #English analyzer with porter stemming, case normalization, latin 1 normalization, and stop words removal
    PORTER_NORMALIZE_STANDARD = "http://schemas.talis.com/2007/bigfoot/analyzers#porter-norm-en".freeze
    
    #English analyzer with porter stemming, case normalization and latin 1 normalization. 
    PORTER_NO_STOP_WORD_STANDARD = "http://schemas.talis.com/2007/bigfoot/analyzers#porter-nostop-norm-en".freeze                    
  end  
  
  #Captures information about a mapped datatype from a Field Predicate Map
  class DatatypeProperty
    #URI for this mapping
    attr_reader :uri
    #RDF predicate URI for the mapped property
    attr_reader :property_uri
    #Short name for the property
    attr_reader :name
    #URI of the analyzer associated with this property
    attr_reader :analyzer
    
    def initialize(uri, property_uri, name, analyzer=nil)
        @uri = uri
        @property_uri = property_uri
        @name = name        
        @analyzer = analyzer
    end

    #Convert this object into an RDF representation. Generates a simple rdf:Description, optionally including namespaces
    #ns:: include namespace declarations   
    def to_rdf(ns=true)
      rdf = "<rdf:Description " 
      if ns
        rdf << " xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:frm=\"#{Pho::Namespaces::FRAME}\" xmlns:bf=\"#{Pho::Namespaces::CONFIG}\" "        
      end 
      rdf << " rdf:about=\"#{@uri}\">"
      rdf << " <frm:property rdf:resource=\"#{@property_uri}\"/>"
      rdf << " <frm:name>#{@name}</frm:name>"
      if @analyzer != nil
        rdf << " <bf:analyzer rdf:resource=\"#{@analyzer}\" />"  
      end      
      rdf << "</rdf:Description>"
      return rdf  
    end
    
  end
  
  #Models a the Field Predicate Map configuration associated with a Platform Store.
  #
  #Class methods exist to create a FieldPredicateMap instance by reading from a store, and to 
  #create DatatypeProperty instances checking that the supplied data is valid according to the 
  #same logic as used by the Platform API.
  class FieldPredicateMap
  
    #Label associated with the resource in the Platform config
    attr_reader :label
    
    #URI for this resource
    attr_reader :uri
    
    #An array of DatatypeProperty instances
    attr_reader :datatype_properties
    

    #Read a FieldPredicateMap instance from the provided store. The method will retrieve the config 
    #as JSON, and parse it to create an object instance.
    def FieldPredicateMap.read_from_store(store)
        resp = store.get_field_predicate_map(Pho::ACCEPT_JSON)        
        if resp.status != 200
          raise "Unable to read Field Predicate Map from store. Response code was #{resp.status}"
        end

        fpmap_uri = store.build_uri("/config/fpmaps/1")
      
        json = JSON.parse( resp.content )
        labels = json[fpmap_uri]["http:\/\/www.w3.org\/2000\/01\/rdf-schema#label"]
        label = ""
        if labels != nil
          label = labels[0]["value"]
        end
        
        fpmap = FieldPredicateMap.new(fpmap_uri, label)
        
        mapped_properties = json[fpmap_uri]["http:\/\/schemas.talis.com\/2006\/frame\/schema#mappedDatatypeProperty"]
        mapped_properties.each { |uri|
          property = json[uri["value"]]
          property_uri = property["http:\/\/schemas.talis.com\/2006\/frame\/schema#property"][0]["value"]
          name = property["http:\/\/schemas.talis.com\/2006\/frame\/schema#name"][0]["value"]
          fpmap << DatatypeProperty.new(uri["value"], property_uri, name)
        }
        
        return fpmap        
    end    

    #Create a DatatypeProperty instance, automatically assigning a unique identifier to it, and 
    #validating the supplied data to ensure it matches the platform rules
    def FieldPredicateMap.create_mapping(store, property_uri, name, analyzer=nil)
        check_value("property_uri", property_uri)
        check_value("name", name)
        if !name.match(/^[a-zA-Z][a-zA-Z0-9]*$/)
          raise "Name does not conform to regular expression: ^[a-zA-Z][a-zA-Z0-9]*$"
        end        
        if analyzer != nil && analyzer.empty?
          analyzer = nil
        end  
        suffix = get_suffix(property_uri)
        mapping_uri = store.build_uri("/config/fpmaps/1##{suffix}")
        return DatatypeProperty.new(mapping_uri, property_uri, name, analyzer)        
    end        
    
    #Create a DatatypeProperty instance, automatically assigning a unique identifier to it, and 
    #validating the supplied data to ensure it matches the platform rules.
    #
    #Then automatically appends it to the provided fpmap instance
    def FieldPredicateMap.add_mapping(fpmap, store, property_uri, name, analyzer=nil)
      mapping = create_mapping(store, property_uri, name, analyzer)
      fpmap << mapping
      return mapping
    end
      
    def initialize(uri, label, datatype_properties = [])
      @uri = uri
      @label = label
      @datatype_properties = datatype_properties
    end
    
    #Append a DatatypeProperty object to this map.
    #Note that the method does not validate the object, and neither does it check for 
    #duplicate mappings.
    def <<(obj)
      @datatype_properties << obj
    end
      
    #Lookup the name mapped to the specified uri
    #
    #uri:: the property uri to search for 
    def get_name(uri)
      p = @datatype_properties.detect { |mapping| uri == mapping.property_uri }
      if p == nil
        return nil
      else
        return p.name        
      end
    end   

    #Lookup the property mapped to the specified name
    #
    #name:: the name to search for 
    def get_property_uri(name)
      p = @datatype_properties.detect { |mapping| name == mapping.name }
      if p == nil
        return nil
      else
        return p.property_uri
      end
    end   
    
    #Is there a mapping for a property with this name?
    def mapped_name?(name)
      return get_property_uri(name) != nil
    end        
    
    #Is there a mapping for this uri?
    def mapped_uri?(uri)
      return get_name(uri) != nil
    end
   
    #Find the DatatypeProperty (if any) with the following name mapping
    def get_by_name(name)
      return @datatype_properties.detect { |mapping| name == mapping.name }
    end
    
    #Find the DatatypeProperty using a property uri
    def get_by_uri(uri)
      return @datatype_properties.detect { |mapping| uri == mapping.property_uri }
    end
    
    #Remove a DatatypeProperty from the collection
    def remove(datatype_property)
      return @datatype_properties.delete(datatype_property)
    end    
    
    #Remove a DatatypeProperty by its mapped name
    def remove_by_name(name)
      p = get_by_name(name)
      if (p != nil)
        return remove(p)
      end   
    end
    
    #Remove a DatatypeProperty by its mapped uri    
    def remove_by_uri(uri)
      p = get_by_uri(uri)
      if (p != nil)
        return remove(p)
      end
    end
    
    #Remove all currently mapped properties
    def remove_all()
      @datatype_properties = Array.new
    end
    
    #Dump this object to an RDF/XML representation suitable for submitting to the Platform
    def to_rdf
      rdf = "<rdf:RDF xmlns:frm=\"#{Pho::Namespaces::FRAME}\" "
      rdf << " xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" "
      rdf << " xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\" "
      rdf << " xmlns:bf=\"#{Pho::Namespaces::CONFIG}\" > " 
   
      rdf << " <rdf:Description rdf:about=\"#{@uri}\"> "
      
      rdf << " <rdf:type rdf:resource=\"#{Pho::Namespaces::CONFIG}FieldPredicateMap\"/> "
      rdf << " <rdfs:label>#{@label}</rdfs:label> "
      
      @datatype_properties.each do |property|
        rdf << " <frm:mappedDatatypeProperty rdf:resource=\"#{property.uri}\"/> "
      end
                  
      rdf << " </rdf:Description>"
      
      @datatype_properties.each do |property|
        rdf << property.to_rdf(false)
      end
            
      rdf << "</rdf:RDF>"
    end 
   
    #Upload an RDF/XML presentation of this object to the provided Platform Store
    def upload(store)
        return store.put_field_predicate_map(self.to_rdf)  
    end 
    
    private
      def FieldPredicateMap.get_suffix(uri)
        return Digest::MD5.hexdigest(uri)
#        candidate_suffix = uri.split("/").last
#        if candidate_suffix.index("#") != -1
#          return candidate_suffix.split("#").last
#        end
#        return candidate_suffix
      end
      
      def FieldPredicateMap.check_value(name, val)
         if val == nil or val.empty?
           raise "#{name} cannot be nil or empty string"
         end        
      end    
  end
    
end