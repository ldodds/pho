module Pho

  #Class that implements the command-line behaviour
  class CommandLine

    def initialize(opts, env, store=nil)
     @opts = opts
     @env = env          
      
     if username() == nil
       raise "no <username>"
     end
     if password() == nil
        raise "no <password>"
     end
     if storename() == nil && store == nil
        raise "no <store>"
     end

     @store = Pho::Store.new(storename(), username(), password()) if store == nil
     @store = store if store != nil
           
    end
        
    def username()
     return @opts["username"] if @opts["username"]
     return @env["TALIS_USER"] if @env["TALIS_USER"]
     return nil  
    end

    def password()
     return @opts["password"] if @opts["password"]
     return @env["TALIS_PASS"] if @env["TALIS_PASS"]
     return nil  
    end
    
    def storename()      
      store = nil
      store = @env["TALIS_STORE"] if @env["TALIS_STORE"]
      store = @opts["store"] if @opts["store"]
      if store != nil && !store.start_with?("http")
          store = "http://api.talis.com/stores/#{store}"  
      end
      return store      
    end
    
    def status()
      status = Pho::Status.read_from_store(@store)
      puts "Status of Store #{@store.storeuri}:\nReadable: #{status.readable?}\nWritable: #{status.writeable?}"      
    end
    
    def backup()
      puts "Submitting Snapshot Job to Store #{@store.storeuri}"
      resp = Pho::Jobs.submit_snapshot(@store, "Reindex", Time.now)
      puts "Monitoring Snapshot Job: #{resp.header["Location"].first}"
      job = Pho::Jobs.wait_for_submitted(resp, @store) do |job, message, time|
         puts "#{time} #{message}"
      end 
      puts "Job Completed"         
      snapshot = Pho::Snapshot.read_from_store(@store)
      puts "Retrieving #{snapshot.url}"
      dir = @opts["dir"] || Dir.tmpdir
      snapshot.backup(@store, dir)
      puts "Download complete. MD5 OK."      
    end
    
    def snapshot()
      puts "Submitting Snapshot Job to Store #{@store.storeuri}"
      resp = Pho::Jobs.submit_snapshot(@store, "Reindex", Time.now)
      puts "Monitoring Snapshot Job #{resp.header["Location"].first}"
      job = Pho::Jobs.wait_for_submitted(resp, @store) do |job, message, time|
        puts "#{time} #{message}"
      end 
      puts "Snapshot Completed"      
    end
    
    def reindex()
      puts "Submitting Reindex Job to Store #{@store.storeuri}"
      resp = Pho::Jobs.submit_reindex(@store, "Reindex", Time.now)
      if resp.status == 201
          puts "Monitoring Reindex Job: #{resp.header["Location"].first}"
      end
      job = Pho::Jobs.wait_for_submitted(resp, @store) do |job, message, time|
          puts "#{time} #{message}"
      end 
      puts "Reindex Completed"      
    end
    
    def reset()
      puts "Resetting Store #{@store.storeuri}"
      resp = Pho::Jobs.submit_reset(@store, "Reset", Time.now)
      puts "Monitoring Reset Job: #{resp.header["Location"].first}"
      job = Pho::Jobs.wait_for_submitted(resp, @store) do |job, message, time|
        puts "#{time} #{message}"
      end 
      puts "Reset Completed"      
    end
    
    def restore()
      url = @opts["url"]     
      if url == nil
        puts "Restoring #{@store.storeuri} from latest snapshot"
        snapshot = Pho::Snapshot.read_from_store(@store)
        url = snapshot.url
      end
      puts "Restoring from #{url}"    
      resp = Pho::Jobs.submit_restore(@store, url, "Reset", Time.now)
      puts "Monitoring Restore Job: #{resp.header["Location"].first}"
      job = Pho::Jobs.wait_for_submitted(resp, @store) do |job, message, time|
        puts "#{time} #{message}"
      end 
      puts "Restore Completed"      
    end
    
    def describe()
      resp = @store.describe( @opts["url"] )
      if resp.status == 200
        puts resp.content
      else
        puts "Error: #{resp.status} #{resp.reason}"
        puts resp.content
      end    
    end  

    def sparql()
      query = File.new( @opts["file"] ).read()
      resp = @store.sparql(query)
      if resp.status == 200
        puts resp.content
      else
        puts "Error: #{resp.status} #{resp.reason}"
        puts resp.content          
      end      
    end

    def store()
      resp = nil
      if @opts["url"]
        puts "Storing remote data: #{@opts["url"]}"
        resp = @store.store_url( @opts["url"] ) 
      elsif @opts["file"]
        puts "Storing local file: #{@opts["file"]}"
        f = File.new( @opts["file"] )
        if File.extname( @opts["file"] ) == ".nt"
          resp = @store.store_file( f, nil, "text/plain" )
        elsif File.extname( @opts["file"] ) == ".ttl"
          resp = @store.store_file( f, nil, "text/turtle" )
        else
          resp = @store.store_file( f )  
        end          
      elsif @opts["dir"]
        puts "Storing contents of directory: #{@opts["dir"]}"
        collection = Pho::RDFCollection.new(@store, @opts["dir"])         
        collection.store()          
        puts collection.summary()
      else     
        #noop
      end 
    
      if resp != nil 
        if resp.status == 204
          puts "Complete"
        else
          puts "Error: #{resp.status} #{resp.reason}"
          puts resp.content
        end         
      end         
    end     
         
    def upload()
      resp = nil
      if @opts["file"]
        f = File.new( @opts["file"] )
        uri = File.basename( @opts["file"] )
        uri = "#{@opts["base"]}/#{uri}" if @opts["base"]            
        mime = MIME::Types.type_for( @opts["file"] )[0].to_s
        puts "Uploading file: #{ @opts["file"] } to /items/#{ uri } as #{mime}"
        resp = @store.upload_item( f , mime , uri )
      elsif @opts["dir"]
        if @opts["dir"] = "."
          @opts["dir"] = File.expand_path(".")
        end
        collection = Pho::FileManagement::FileManager.new(@store, @opts["dir"], @opts["base"])
        if @opts["force"]
          puts "Resetting tracking files for directory #{@opts["dir"]}"
          collection.reset()
        end
        if @opts["retry"]
          puts "Retrying failures in: #{@opts["dir"]}"        
          if @opts["traverse"]
            collection.retry_failures()          
            puts collection.summary(:traverse)
          else
            collection.retry_failures()          
            puts collection.summary()            
          end                   
        else
          puts "Uploading contents of directory: #{@opts["dir"]}"        
          if @opts["traverse"]
            collection.store(:traverse)          
            puts collection.summary(:traverse)
          else
            collection.store()          
            puts collection.summary()            
          end                   
        end        
      else     
        #noop
      end 
    
      if resp != nil
        if resp.status == 204
          puts "Complete"
        else
          puts "Error: #{resp.status} #{resp.reason}"
          puts resp.content
        end         
      end                
    end
    
    def fpmap(out=$stdout)
      
      if @opts["raw"]
        resp = @store.get_field_predicate_map(Pho::ACCEPT_RDF)        
        if resp.status != 200
          out.puts "Unable to read Field Predicate Map from store. Response code was #{resp.status}"
        else
          out.puts resp.content
        end
      else  
        fpmap = Pho::FieldPredicateMap.read_from_store(@store)
        mappings = fpmap.datatype_properties.sort { |x,y| x.name <=> y.name }
        mappings.each do |mapping|        
          analyzer = mapping.analyzer
          if analyzer != nil
            Pho::Analyzers.constants.each do |c|
              if analyzer == Pho::Analyzers.const_get(c)
                analyzer = c
              end
            end
          end
          out.puts "#{mapping.name} -> #{mapping.property_uri}" if analyzer == nil
          out.puts "#{mapping.name} -> #{mapping.property_uri} (#{mapping.analyzer})" if analyzer != nil
        end 
      
      end
            
    end

    def queryprofile(out=$stdout)

      if @opts["raw"]
        resp = @store.get_query_profile(Pho::ACCEPT_RDF)        
        if resp.status != 200
          out.puts "Unable to read Query Profile from store. Response code was #{resp.status}"
        else
          out.puts resp.content
        end
      else  
        queryprofile = Pho::QueryProfile.read_from_store(@store)
        field_weights = queryprofile.field_weights()
        field_weights = field_weights.sort { |x,y| x.name <=> y.name }
        field_weights.each do |weighting|
          out.puts "#{weighting.name} -> #{weighting.weight}"
        end      
      end
            
    end

    def add_mapping(out=$stdout)
      fpmap = Pho::FieldPredicateMap.read_from_store(@store)
      mapping = Pho::FieldPredicateMap.create_mapping(@store, @opts["predicate"], @opts["field"], @opts["analyzer"])

      removed = fpmap.remove_by_name(@opts["field"])
      if removed != nil
        out.puts("Replacing mapping for #{@opts["field"]}")  
      end      
      fpmap << mapping
      resp = fpmap.upload(@store)
      if resp.status != 200
        out.puts "Unable to update FieldPredicate map in store. Response code was #{resp.status}"
      else
        out.puts "FieldPredicate map successfully updated"
      end
    end

    def add_weight(out=$stdout)
      qp = Pho::QueryProfile.read_from_store(@store)
      weight = Pho::QueryProfile.create_weighting(@store, @opts["field"], @opts["weight"])
      
      removed = qp.remove_by_name( @opts["field"] )
      if removed != nil
          out.puts("Replacing weighting for #{@opts["field"]}")        
      end
      qp << weight
      resp = qp.upload(@store)
      if resp.status != 200
        out.puts "Unable to update QueryProfile in store. Response code was #{resp.status}"
      else
        out.puts "QueryProfile successfully updated"
      end      
    end
    
    #TODO remove_mapping
    
  #End CommandLine      
  end
  
end
