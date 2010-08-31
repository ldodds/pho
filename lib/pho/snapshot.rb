module Pho

  require 'digest/md5'
  require 'tmpdir'
  
  #In the Talis Platform a "snapshot" is an backup of the contents of a Store
  #
  #A snapshot consists of a tar file that contains all data (contentbox and metabox) 
  #in the store. The snapshot also contains the store configuration but this is encrypted
  #and not intended for reuse.
  #
  #A snapshot can be generated (or scheduled) using the Store.snapshot method.
  # 
  class Snapshot
    
    #The URL from which the snapshot can be retrieved
    attr_reader :url
    
    #The URL from which the MD5 for the snapshot can be retrieved
    attr_reader :md5_url

    #Size of the snapshot
    attr_reader :size
    
    #Units for Size, e.g. KB
    attr_reader :units

    #Date when snapshot was taken
    attr_reader :date
    
    # Read snapshot data from the given store
    #
    # store:: reference to a Store object
    def Snapshot.read_from_store(store)
      resp = store.get_snapshots()
      
      if (resp.status > 200)
        raise "Response was not successful. Status code was: #{resp.status}"
      end
      content = resp.content
      
      return parse(store.storeuri, content)  
    end    
    
    #Class method to parse the RDF response from the API, e.g. as produced by the Store.get_snapshots method 
    #and create a new Snapshot object. At the moment the Platform only supports single snapshot.
    #
    #If the response was an error, then an exception will be thrown. If no snapshot can be found, then
    #the method returns nil
    #
    # storeuri:: URI of the store
    # content:: response from the API
    def Snapshot.parse(storeuri, content)
            
      doc = REXML::Document.new(content)
      root = doc.root
      
      store = REXML::XPath.first(root, "//*[@rdf:about='#{storeuri}']", Pho::Namespaces::MAPPING )
      #not found if there's no snapshot for this store
      if store == nil
        return nil
      end
      snapshot = REXML::XPath.first(store, "bf:snapshot", Pho::Namespaces::MAPPING)
      snapshot_url = snapshot.attributes["rdf:resource"] 
      snapshot_el = REXML::XPath.first(root, "//*[@rdf:about='#{snapshot_url}']", Pho::Namespaces::MAPPING )
      
      el = REXML::XPath.first(snapshot_el, "bf:md5", Pho::Namespaces::MAPPING)
      snapshot_md5_url = el.attributes["rdf:resource"]      

      el = REXML::XPath.first(snapshot_el, "bf:filesize", Pho::Namespaces::MAPPING)      
      snapshot_size = el.text.split(" ")[0]
      snapshot_units = el.text.split(" ")[1]
      
      el = REXML::XPath.first(snapshot_el, "dc:date", Pho::Namespaces::MAPPING)
      snapshot_date = el.text 
      
      return Snapshot.new(snapshot_url, snapshot_md5_url, snapshot_size, snapshot_units, snapshot_date)
      
    end
        
    def initialize(url, md5_url, size, units, date)
      @url = url
      @md5_url = md5_url
      @size = size
      @units = units      
      @date = date
    end   
    

    #Read the published MD5 value
    def read_md5(client=HttpClient.new())
      return client.get_content(@md5_url)
    end    
    
    # Download this snapshot to the specified directory. Will automatically calculate an MD5 checksum for  
    # the download and compare it against the published value. If they don't match then a RuntimeError will 
    # be raised
    #
    # store:: the store to backup
    # dir:: directory in which snapshot will be stored
    def backup(store, dir=Dir.tmpdir)
      
      published_md5 = read_md5(store.client)
      
      digest = Digest::MD5.new()

      filename = @url.split("/").last
      file = File.open( File.join(dir, filename), "w" ) do |file|

        #FIXME: this is not efficient as the snapshot may be very large and this
        #will just read all of the data into memory
        content = store.client.get_content(@url)
        file.print(content)
        digest << content
        
      end
      
      calc_md5 = digest.hexdigest
      if (calc_md5 != published_md5)
        raise "Calculated digest of #{calc_md5} but does not match published md5 #{published_md5}"
      end
    end
        
  end
        
end
