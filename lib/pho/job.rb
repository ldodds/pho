module Pho

#TODO job deletion
        
  class Jobs

    RESET = "http://schemas.talis.com/2006/bigfoot/configuration#ResetDataJob".freeze
    SNAPSHOT = "http://schemas.talis.com/2006/bigfoot/configuration#SnapshotJob".freeze
    REINDEX = "http://schemas.talis.com/2006/bigfoot/configuration#ReindexJob".freeze   
    RESTORE = "http://schemas.talis.com/2006/bigfoot/configuration#RestoreJob".freeze

    #Reads the current list of scheduled jobs from the provided store. Returns an array of 
    #job names
    #
    # store:: store from which to read the scheduled job list
    def Jobs.read_from_store(store)
      resp = store.get_jobs()
      if resp.status != 200
        raise "Unable to read jobs from store. Status was {resp.status}"
      end
      jobs = Array.new
      
      doc = REXML::Document.new(resp.content)
      REXML::XPath.each(doc.root, "//bf:job", Pho::Namespaces::MAPPING) do |el|
        jobs << el.attributes["rdf:resource"]
      end
      return jobs
      
    end

    #Submit a reset job to the Platform
    #
    #This method submits the job, and will return an HTTP:Message indicating the 
    #response from the Platform. Client code should check this for success. As job
    #processing may not be immediate, clients should determine the URI of the newly created 
    #job and then monitor the jobs status if they need to wait for the job to finish.
    def Jobs.submit_reset(store, label="Reset my store", t=Time.now)
      return submit_job(store, Pho::Jobs::RESET, label, t)
    end

    #Submit a reindex job to the Platform
    #
    #This method submits the job, and will return an HTTP:Message indicating the 
    #response from the Platform. Client code should check this for success. As job
    #processing may not be immediate, clients should determine the URI of the newly created 
    #job and then monitor the jobs status if they need to wait for the job to finish.            
    def Jobs.submit_reindex(store, label="Reindex my store", t=Time.now)
      return submit_job(store, Pho::Jobs::REINDEX, label, t)      
    end
    
    #Submit a snapshot job to the Platform    
    #
    #This method submits the job, and will return an HTTP:Message indicating the 
    #response from the Platform. Client code should check this for success. As job
    #processing may not be immediate, clients should determine the URI of the newly created 
    #job and then monitor the jobs status if they need to wait for the job to finish.    
    def Jobs.submit_snapshot(store, label="Snapshot my store", t=Time.now)
      return submit_job(store, Pho::Jobs::SNAPSHOT, label, t)
    end  

    #Submit a restore job to the Platform    
    #
    #This method submits the job, and will return an HTTP:Message indicating the 
    #response from the Platform. Client code should check this for success. As job
    #processing may not be immediate, clients should determine the URI of the newly created 
    #job and then monitor the jobs status if they need to wait for the job to finish.    
    def Jobs.submit_restore(store, snapshot_uri, label="Restore my snapshot", t=Time.now)
      return submit_job(store, Pho::Jobs::RESTORE, label, t, snapshot_uri)
    end        
    
    #Generic submit job method    
    def Jobs.submit_job(store, jobtype, label, t=Time.now, snapshot_uri=nil)
      store.submit_job( build_job_request(jobtype, label, t, snapshot_uri) )
    end

    # Construct an RDF/XML document containing a job request for submitting to the Platform.
    #
    # t:: a Time object, specifying the time at which the request should be carried out
    def Jobs.build_job_request(type, label, t=Time.now, snapshot_uri=nil)
      
      time = t.getutc.strftime("%Y-%m-%dT%H:%M:%SZ")
      data = "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" "
      data << " xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\" " 
      data << " xmlns:bf=\"http://schemas.talis.com/2006/bigfoot/configuration#\"> " 
      data << " <bf:JobRequest>"
      data << "   <rdfs:label>#{label}</rdfs:label>"    
      data << "   <bf:jobType rdf:resource=\"#{type}\"/>"
      data << "   <bf:startTime>#{time}</bf:startTime>"
      
      if (snapshot_uri != nil)
        data << "   <bf:snapshotUri rdf:resource=\"#{snapshot_uri}\"/>"        
      end
      
      data << " </bf:JobRequest>"
      data << "</rdf:RDF>"
      return data      
    end    

    #Wait for a newly submitted job to finish
    def Jobs.wait_for_submitted(resp, store, interval=1, &block)
      if resp.status != 201
        raise "Unable to wait, job was not created. Status was #{resp.status}"
      end
      job_url = resp.header["Location"].first
      return wait_for(job_url, store, interval, &block)
    end
    
    #Wait for the specified job to finish
    #
    #The method will repeatedly contact the Platform to determine whether the job has finished
    #executing. The requests are made at configurable intervals (once a minute by default). If 
    #a block is supplied, then it is passed a reference to the Job (containing current progress 
    #updates) after each request. The Job object is returned once completed.
    #
    # uri:: URI of the job to wait for
    # store:: the store on which the job is running
    # interval:: the interval at which checks will be made, in minutes. Default is 1
    def Jobs.wait_for(uri, store, interval=1, &block)
        updates = 0
        job = Job.read_from_store(uri, store)
        updates = yield_job_update(job, updates, &block)
        while !job.completed?
          sleep interval*60
          job = Job.read_from_store(uri, store)
          updates = yield_job_update(job, updates, &block)
        end
        return job
    end
    
    protected
    
      def Jobs.yield_job_update(job, updates)
        if block_given?
            if job.started?
              
              #only yield start message if we've not seen any updates
              if updates == 0
                yield job, job.start_message, job.actual_start_time  
              end
                            
              if job.progress_updates.length > 0
                unseen = job.progress_updates[updates, job.progress_updates.length] 
                unseen.each do |update|
                  yield job, update.message, update.time
                end
                updates = job.progress_updates.length                
              end
              
              if job.completed?
                  yield job, job.completion_message, job.end_time
              end
              
            end
        end        
        return updates  
      end
      
  end
  
  #Simple object encapsulating the status message and time for a job update
  class JobUpdate
  
    #the status message
    attr_accessor :message
    #the time at which the update was logged
    attr_accessor :time
    
  end  
  
  # A Platform Job
  #
  # Instances of this class encapsulate all of the core metadata relating to a Platform Job.
  # This includes not only the timing information but also the completion status, etc.
  # 
  # The class provides convenience methods for retrieving and parsing data about a specific
  # Job from a platform store
  class Job

    SUCCESS = "http://schemas.talis.com/2006/bigfoot/configuration#success"
    ABORTED = "http://schemas.talis.com/2006/bigfoot/configuration#aborted"            
          
    #URI of the job
    attr_reader :uri
    #Label associated with job
    attr_reader :label
    #Type of job
    attr_reader :type
    #Date-time that the job was created
    attr_reader :created
    #Date-time that the job will start
    attr_reader :start_time
    #Date-time that the job actually started
    attr_accessor :actual_start_time    
    #URI of snapshot to load. (For RestoreJob only)
    attr_accessor :snapshot_uri
    #Message recorded at the time the job started
    attr_accessor :start_message
    #An array of JobUpdate instances. May be empty if no updates have been logged
    attr_accessor :progress_updates
    #URI indicating completion status of the job
    attr_accessor :completion_status
    #Completion message
    attr_accessor :completion_message
    #Date time that the job actually completed
    attr_accessor :end_time
    
    #Constructor. Used in the reading/parsing code
    #
    #uri:: a unique identifier for the job
    #label:: a description of the job
    #type:: the type of the job, e.g. Pho::Jobs::RESTORE
    #created:: date-time the job was created in the system
    #start_time:: scheduled start time for the job   
    def initialize(uri, label, type, start_time, created=nil)
      @uri = uri
      @label = label
      @type = type
      @created = created
      @start_time = start_time
      @progress_updates = Array.new
    end
    
    #Read a job from a store
    #
    #uri:: uri of the job to read
    #store:: store from which the job will be read 
    def Job.read_from_store(uri, store)
      resp = store.get_job(uri)
      if resp.status != 200
        raise "Unable to read job from store. Response code was #{resp.status}"
      end
      
      return parse(uri, resp.content)      
    end    
    
    #Parses job metadata returned from the platform as RDF/XML, creating a fully populated
    #Job instance
    #
    #uri:: uri of the job to be parsed
    #xml:: the RDF/XML text to be parsed
    def Job.parse(uri, xml)
      doc = REXML::Document.new(xml)
      root = doc.root
       
      #job_el = REXML::XPath.first(root, "rdf:Description[rdf:type]", Pho::Namespaces::MAPPING )      
      job_el = REXML::XPath.first(root, "//*[@rdf:about='#{uri}']", Pho::Namespaces::MAPPING )
      uri = job_el.attributes["rdf:about"]
      label = REXML::XPath.first(job_el, "rdfs:label", Pho::Namespaces::MAPPING ).text
      type_el = REXML::XPath.first(job_el, "rdf:type", Pho::Namespaces::MAPPING )
      type = type_el.attributes["rdf:resource"]
      created = REXML::XPath.first(job_el, "dcterms:created", Pho::Namespaces::MAPPING ).text
      start_time = REXML::XPath.first(job_el, "bf:startTime", Pho::Namespaces::MAPPING ).text
   
      job = Job.new(uri, label, type, start_time, created)
      if type == Pho::Jobs::RESTORE
        with_first(job_el, "bf:snapshotUri") do |uri|
          job.snapshot_uri = uri.attributes["rdf:resource"]
        end
      end
            
      with_first(job_el, "bf:actualStartTime") do |el|
        job.actual_start_time = el.text
      end
      with_first(job_el, "bf:startMessage") do |el|
        job.start_message = el.text
      end
      with_first(job_el, "bf:completionMessage") do |el|
        job.completion_message = el.text
      end
      with_first(job_el, "bf:endTime") do |el|
          job.end_time = el.text
      end      
      with_first(job_el, "bf:completionStatus") do |el|
        job.completion_status = el.attributes["rdf:resource"]
      end
      with_each(job_el, "bf:progressUpdate") do |el|
        update = JobUpdate.new
        with_first(el, "bf:progressUpdateMessage") do |msg|
          update.message = msg.text
        end
        with_first(el, "bf:progressUpdateTime") do |time|
          update.time = time.text
        end
        job.progress_updates << update
      end
         
      return job 
      
    end
    
    def progress_updates()
      @progress_updates.sort! { |x,y|
        x.time <=> y.time 
      }
      return @progress_updates       
    end
    
    #Has the job started?
    def started?
      return @actual_start_time != nil
    end
    
    #Has the job completed?
    def completed?
      return @completion_status != nil
    end
    
    #Was the job successful?
    def successful?
      return self.completed? && @completion_status == Pho::Job::SUCCESS
    end
    
    #Is the job still running?
    def running?
      return started? && !completed?
    end  
    
    protected
        
      def Job.with_first(el, xpath)
        found_el = REXML::XPath.first(el, xpath, Pho::Namespaces::MAPPING)
        if found_el != nil
          yield found_el
        end
      end
      
      def Job.with_each(el, xpath)
        REXML::XPath.each(el, xpath, Pho::Namespaces::MAPPING) do |e|
          root = e.document.root
          uri = e.attributes["rdf:resource"]
          ref_el = REXML::XPath.first(root, "//*[@rdf:about='#{uri}']", Pho::Namespaces::MAPPING)
          yield ref_el
        end
      end      
  end
    
end