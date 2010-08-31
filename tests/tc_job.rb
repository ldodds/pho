$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'
require 'rexml/document'

class JobTest < Test::Unit::TestCase
  
  JOB_COLLECTION = <<-EOL
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:j.0="http://schemas.talis.com/2005/dir/schema#"
      xmlns:j.1="http://schemas.talis.com/2006/bigfoot/configuration#" > 
    <rdf:Description rdf:about="http://api.talis.com/stores/testing/jobs">
      <rdf:type rdf:resource="http://schemas.talis.com/2006/bigfoot/configuration#ScheduledJobCollection"/>
      <j.1:job rdf:resource="http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed"/>
      <j.0:etag>"7f27f79a-13ee-4234-9291-f400fd296a0b"</j.0:etag>
    </rdf:Description>
  </rdf:RDF>  
EOL
  
  JOB = <<-EOL
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:j.0="http://purl.org/dc/terms/"
      xmlns:j.1="http://schemas.talis.com/2006/bigfoot/configuration#"
      xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" > 
    <rdf:Description rdf:about="http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed">
      <rdf:type rdf:resource="http://schemas.talis.com/2006/bigfoot/configuration#ResetDataJob"/>      
      <rdfs:label>Reset Store Job</rdfs:label>
      <j.0:created rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:30:19Z</j.0:created>
      <j.1:startTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:35:00Z</j.1:startTime>
    </rdf:Description>
  </rdf:RDF>  
EOL

  RESTORE_JOB = <<-EOL
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:j.0="http://purl.org/dc/terms/"
      xmlns:j.1="http://schemas.talis.com/2006/bigfoot/configuration#"
      xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" > 
    <rdf:Description rdf:about="http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed">
      <rdf:type rdf:resource="http://schemas.talis.com/2006/bigfoot/configuration#RestoreJob"/>
      <j.1:snapshotUri rdf:resource="http://www.example.org/snapshot.tar"/>      
      <rdfs:label>Restore Store Job</rdfs:label>
      <j.0:created rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:30:19Z</j.0:created>
      <j.1:startTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:35:00Z</j.1:startTime>
    </rdf:Description>
  </rdf:RDF>  
EOL
  
  RUNNING_JOB = <<-EOL
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:j.0="http://purl.org/dc/terms/"
      xmlns:j.1="http://schemas.talis.com/2006/bigfoot/configuration#"
      xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" > 
    <rdf:Description rdf:about="http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed">
      <rdf:type rdf:resource="http://schemas.talis.com/2006/bigfoot/configuration#ResetDataJob"/>
      <rdfs:label>Reset Store Job</rdfs:label>
      <j.0:created rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:30:19Z</j.0:created>
      <j.1:startTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:35:00Z</j.1:startTime>
      <j.1:actualStartTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:35:12Z</j.1:actualStartTime>
      <j.1:startMessage>ResetDataTask starting</j.1:startMessage>
      <j.1:progressUpdate rdf:resource="http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed/867fd0df-e127-4e17-03b-376af409f2a6"/>
    </rdf:Description>
    <rdf:Description rdf:about="http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed/867fd0df-e127-4e17-03b-376af409f2a6">
      <j.1:progressUpdateMessage>Reset Data job running for store.</j.1:progressUpdateMessage>
      <j.1:progressUpdateTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:35:15Z</j.1:progressUpdateTime>
    </rdf:Description>
  </rdf:RDF>  
EOL

  #originally had mismatched uris
  SUCCESSFUL_JOB = <<-EOL
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:j.0="http://purl.org/dc/terms/"
      xmlns:j.1="http://schemas.talis.com/2006/bigfoot/configuration#"
      xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" > 
    <rdf:Description rdf:about="http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed">
      <rdf:type rdf:resource="http://schemas.talis.com/2006/bigfoot/configuration#ResetDataJob"/>
      <rdfs:label>Reset Store Job</rdfs:label>
      <j.0:created rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:30:19Z</j.0:created>
      <j.1:startTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:35:00Z</j.1:startTime>
      <j.1:actualStartTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:35:12Z</j.1:actualStartTime>
      <j.1:startMessage>ResetDataTask starting</j.1:startMessage>
      <j.1:progressUpdate rdf:resource="http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed/867fd0df-e127-4e17-03b-376af409f2a6"/>
      <j.1:endTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:35:40Z</j.1:endTime>
      <j.1:completionMessage>Reset store Complete.</j.1:completionMessage>
      <j.1:completionStatus rdf:resource="http://schemas.talis.com/2006/bigfoot/configuration#success"/>
    </rdf:Description>
    <rdf:Description rdf:about="http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed/867fd0df-e127-4e17-03b-376af409f2a6">
      <j.1:progressUpdateMessage>Reset Data job running for store.</j.1:progressUpdateMessage>
      <j.1:progressUpdateTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T16:35:15Z</j.1:progressUpdateTime>
    </rdf:Description>
  </rdf:RDF>  
EOL

  #no snapshot_uri?
  ABORTED_JOB = <<-EOL
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:j.0="http://purl.org/dc/terms/"
      xmlns:j.1="http://schemas.talis.com/2006/bigfoot/configuration#"
      xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" > 
    <rdf:Description rdf:about="http://api.talis.com/stores/testing/jobs/dbd51dfd-dd17-4bf1-a7d0-4a651587de14">
      <rdf:type rdf:resource="http://schemas.talis.com/2006/bigfoot/configuration#RestoreJob"/>
      <rdfs:label>Restore Snapshot Job</rdfs:label>
      <j.0:created rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T17:02:19Z</j.0:created>
      <j.1:startTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T17:02:19Z</j.1:startTime>
      <j.1:actualStartTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T17:03:12Z</j.1:actualStartTime>
      <j.1:startMessage>Restore store task starting using snapshot http://i-dont-exist.com/20080801105153.tar</j.1:startMessage>
      <j.1:endTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2009-01-30T17:03:13Z</j.1:endTime>
      <j.1:completionStatus rdf:resource="http://schemas.talis.com/2006/bigfoot/configuration#aborted"/>
      <j.1:completionMessage>Unable to retrieve snapshot: http://i-dont-exist.com/20080801105153.tar Status code returned was: 404</j.1:completionMessage>
    </rdf:Description>
  </rdf:RDF>  
EOL

    def test_read_from_store()
      mc = mock()
      mc.expects(:set_auth)
      mc.expects(:get).with("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", 
        anything, {"Accept" => "application/rdf+xml"}).returns(
        HTTP::Message.new_response(JOB) )
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)  
      job = Pho::Job.read_from_store("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", store);
      assert_not_nil(job)
      assert_equal("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", job.uri)
      assert_equal("Reset Store Job", job.label)
      assert_equal(Pho::Jobs::RESET, job.type)
      assert_equal("2009-01-30T16:30:19Z", job.created)
      assert_equal("2009-01-30T16:35:00Z", job.start_time)            
    end
    
    def test_read_restore_job_from_store()
      mc = mock()
      mc.expects(:set_auth)
      mc.expects(:get).with("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", 
        anything, {"Accept" => "application/rdf+xml"}).returns(
        HTTP::Message.new_response(RESTORE_JOB) )
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)  
      job = Pho::Job.read_from_store("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", store);
      assert_not_nil(job)
      assert_equal("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", job.uri)
      assert_equal("Restore Store Job", job.label)
      assert_equal(Pho::Jobs::RESTORE, job.type)
      assert_equal("2009-01-30T16:30:19Z", job.created)
      assert_equal("2009-01-30T16:35:00Z", job.start_time)
      assert_equal("http://www.example.org/snapshot.tar", job.snapshot_uri)
                  
    end
    
    def test_read_running_job()
      mc = mock()
      mc.expects(:set_auth)
      mc.expects(:get).with("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", 
        anything, {"Accept" => "application/rdf+xml"}).returns(
        HTTP::Message.new_response(RUNNING_JOB) )
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)  
      job = Pho::Job.read_from_store("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", store);
      assert_not_nil(job)
      assert_equal("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", job.uri)
      assert_equal("Reset Store Job", job.label)
      assert_equal(Pho::Jobs::RESET, job.type)
      assert_equal("2009-01-30T16:30:19Z", job.created)
      assert_equal("2009-01-30T16:35:00Z", job.start_time)            
      assert_equal("2009-01-30T16:35:12Z", job.actual_start_time)
      assert_equal(true, job.started?)
      assert_equal("ResetDataTask starting", job.start_message)
      
      progress_updates = job.progress_updates
      assert_not_nil(progress_updates)
      assert_equal(1, progress_updates.size)
      
      update = progress_updates[0]
      assert_equal("2009-01-30T16:35:15Z", update.time)
      assert_equal("Reset Data job running for store.", update.message)
   
      assert_equal(false, job.completed?)
      assert_equal(false, job.successful?)
      assert_equal(true, job.running?)                    
    end
    
    def test_read_successful_job()
      mc = mock()
      mc.expects(:set_auth)
      mc.expects(:get).with("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", 
        anything, {"Accept" => "application/rdf+xml"}).returns(
        HTTP::Message.new_response(SUCCESSFUL_JOB) )
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)  
      job = Pho::Job.read_from_store("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", store);
      assert_not_nil(job)
      assert_equal("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", job.uri)
      assert_equal("Reset Store Job", job.label)
      assert_equal(Pho::Jobs::RESET, job.type)
      assert_equal("2009-01-30T16:30:19Z", job.created)
      assert_equal("2009-01-30T16:35:00Z", job.start_time)            
      assert_equal("2009-01-30T16:35:12Z", job.actual_start_time)
      assert_equal(true, job.started?)
      assert_equal("ResetDataTask starting", job.start_message)
      
      progress_updates = job.progress_updates
      assert_not_nil(progress_updates)
      assert_equal(1, progress_updates.size)
      
      update = progress_updates[0]
      assert_equal("2009-01-30T16:35:15Z", update.time)
      assert_equal("Reset Data job running for store.", update.message)
      assert_equal("2009-01-30T16:35:40Z", job.end_time)
      assert_equal(true, job.completed?)
      assert_equal(true, job.successful?)
      assert_equal(false, job.running?)                    
    end        
    
    
    def test_read_aborted_job()
      mc = mock()
      mc.expects(:set_auth)
      mc.expects(:get).with("http://api.talis.com/stores/testing/jobs/dbd51dfd-dd17-4bf1-a7d0-4a651587de14", 
        anything, {"Accept" => "application/rdf+xml"}).returns(
        HTTP::Message.new_response(ABORTED_JOB) )
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)  
      job = Pho::Job.read_from_store("http://api.talis.com/stores/testing/jobs/dbd51dfd-dd17-4bf1-a7d0-4a651587de14", store);
      assert_not_nil(job)
      assert_equal("http://api.talis.com/stores/testing/jobs/dbd51dfd-dd17-4bf1-a7d0-4a651587de14", job.uri)
      assert_equal("Restore Snapshot Job", job.label)
      assert_equal(Pho::Jobs::RESTORE, job.type)
      assert_equal("2009-01-30T17:02:19Z", job.created)
      assert_equal("2009-01-30T17:02:19Z", job.start_time)            
      assert_equal("2009-01-30T17:03:12Z", job.actual_start_time)
      assert_equal("2009-01-30T17:03:13Z", job.end_time)
      assert_equal(true, job.started?)
      assert_equal("Restore store task starting using snapshot http://i-dont-exist.com/20080801105153.tar", job.start_message)
      assert_equal("Unable to retrieve snapshot: http://i-dont-exist.com/20080801105153.tar Status code returned was: 404", job.completion_message)
      assert_equal(0, job.progress_updates.size)
      assert_equal(true, job.completed?)
      assert_equal(false, job.successful?)
      assert_equal(false, job.running?)      
    end
    
    def test_read_jobs()
        mc = mock()
        mc.expects(:set_auth)
        mc.expects(:get).with("http://api.talis.com/stores/testing/jobs", anything, {"Accept" => "application/rdf+xml"}).returns(
          HTTP::Message.new_response(JOB_COLLECTION))
          
        store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
        jobs = Pho::Jobs.read_from_store(store)
        assert_not_nil(jobs)
        assert_equal(1, jobs.size)
        assert_equal("http://api.talis.com/stores/testing/jobs/4d63b413-8819-49f2-8936-a819359b06ed", jobs[0])
              
    end
end