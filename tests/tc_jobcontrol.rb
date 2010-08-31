$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class JobControlTest < Test::Unit::TestCase
  
  def test_build_job_request
    #store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    job_req = Pho::Jobs.build_job_request("http://www.example.org/ns/jobtype", "test label", Time.now)
    
    assert_equal(true, job_req.index( "<rdfs:label>test label</rdfs:label>") != nil )
    assert_equal(true, job_req.index( "rdf:resource=\"""http://www.example.org/ns/jobtype\"""/>") != nil )
  end

  def set_expectations(url, mc, jobtype, label)
    mc.expects(:set_auth)
    mc.expects(:post).with() { |passedurl, data, headers|
      assert_equal("#{url}/jobs", passedurl)
      assert_equal("application/rdf+xml", headers["Content-Type"])
      
      assert_equal(true, data.index( "<rdfs:label>#{label}</rdfs:label>") != nil )
      assert_equal(true, data.index( "rdf:resource=\"""#{jobtype}\"""/>") != nil )      
      true
    }    
  end
    
  def test_submit_job
    mc = mock()
    set_expectations("http://api.talis.com/stores/testing", mc, "http://www.example.org/ns/jobtype", "test label" )
                    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    job_req = Pho::Jobs.submit_job(store, "http://www.example.org/ns/jobtype", "test label")
    
  end
  
  def test_reset
    mc = mock()
    set_expectations("http://api.talis.com/stores/testing", mc, Pho::Jobs::RESET, "Reset my store" )
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    job_req = Pho::Jobs.submit_reset(store)
  end

  def test_reindex
    mc = mock()
    set_expectations("http://api.talis.com/stores/testing", mc, Pho::Jobs::REINDEX, "Reindex my store" )

    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    job_req = Pho::Jobs.submit_reindex(store)    
  end

  def test_snapshot
    mc = mock()
    set_expectations("http://api.talis.com/stores/testing", mc, Pho::Jobs::SNAPSHOT, "Snapshot my store" )
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    job_req = Pho::Jobs.submit_snapshot(store)
  end
  
  def test_restore
    mc = mock()
    set_expectations("http://api.talis.com/stores/testing", mc, Pho::Jobs::RESTORE, "Restore my snapshot" )    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    job_req = Pho::Jobs.submit_restore(store,"http://www.example.com.tar")        
  end
  
  def test_yield_job_updates_requires_block
    mc = mock()    
    updates = Pho::Jobs.yield_job_update(mc, 0)
    assert_equal(0, updates)
    
  end
  
  def test_yield_job_updates_does_not_yield_if_not_started
    mc = mock()
    mc.expects(:started?).returns(false)
    
    updates = Pho::Jobs.yield_job_update(mc, 0) do |job, message, time|
       raise   
    end
    
    assert_equal(0, updates)
    
  end
  
  def test_yield_job_updates_yields_if_started
    mc = mock()
    mc.expects(:started?).returns(true)
    mc.expects(:start_message).returns("Started")
    mc.expects(:actual_start_time).returns("2009-01-30T16:35:00Z")
    mc.expects(:progress_updates).returns(Array.new)
    mc.expects(:completed?).returns(false)
    
    updates = Pho::Jobs.yield_job_update(mc, 0) do |job, message, time|
        assert_equal("Started", message)
        assert_equal("2009-01-30T16:35:00Z", time)      
    end
    
    assert_equal(0, updates)
    
  end
  
  def test_yield_job_updates_yields_progress_updates
    mc = mock()
    mc.expects(:started?).returns(true)
    mc.expects(:start_message).returns("Started")
    mc.expects(:actual_start_time).returns("2009-01-30T16:35:00Z")
    
    updates = Array.new
    update = Pho::JobUpdate.new
    update.message = "Update"
    update.time = "2009-01-30T16:40:00Z"
    updates << update
     
    mc.expects(:progress_updates).at_least_once().returns(updates)
    mc.expects(:completed?).returns(false)
    
    calls = 0
    updates = Pho::Jobs.yield_job_update(mc, 0) do |job, message, time|
        if calls == 0
          assert_equal("Started", message)
          assert_equal("2009-01-30T16:35:00Z", time)      
          calls += 1          
        elsif calls == 1
          assert_equal("Update", message)
          assert_equal("2009-01-30T16:40:00Z", time)
          calls += 1          
        else 
          raise                          
        end        
    end
    
    assert_equal(1, updates)
    
  end
  
  def test_yield_job_updates_yields_completion_message
    mc = mock()
    mc.expects(:started?).returns(true)
    mc.expects(:start_message).returns("Started")
    mc.expects(:actual_start_time).returns("2009-01-30T16:35:00Z")
    
    updates = Array.new
    update = Pho::JobUpdate.new
    update.message = "Update"
    update.time = "2009-01-30T16:40:00Z"
    updates << update
     
    mc.expects(:progress_updates).at_least_once().returns(updates)
    mc.expects(:completed?).returns(true)
    mc.expects(:completion_message).returns("Completed")
    mc.expects(:end_time).returns("2009-01-30T16:45:00Z")
    
    calls = 0
    updates = Pho::Jobs.yield_job_update(mc, 0) do |job, message, time|
        if calls == 0
          assert_equal("Started", message)
          assert_equal("2009-01-30T16:35:00Z", time)      
          calls += 1          
        elsif calls == 1
          assert_equal("Update", message)
          assert_equal("2009-01-30T16:40:00Z", time)
          calls += 1          
        elsif calls == 2 
          assert_equal("Completed", message)
          assert_equal("2009-01-30T16:45:00Z", time)
          calls += 1          
        else 
          raise       
        end        
    end
    
    assert_equal(1, updates)
    
  end
  
  def test_yield_job_updates_yields_only_unseen_updates
    mc = mock()
    mc.expects(:started?).returns(true)
    
    updates = Array.new
    
    5.times do |i|
      update = Pho::JobUpdate.new
      update.message = "Update #{i+1}"
      update.time = "2009-01-30T16:40:00Z"
      updates << update        
    end
    
    mc.expects(:progress_updates).at_least_once().returns(updates)
    mc.expects(:completed?).returns(false)
    
    calls = 0
    msgs = Pho::Jobs.yield_job_update(mc, 2) do |job, message, time|
        if calls == 0
          assert_equal("Update 3", message)      
          calls += 1          
        elsif calls == 1
          assert_equal("Update 4", message)
          calls += 1          
        elsif calls == 2 
          assert_equal("Update 5", message)
          calls += 1          
        else 
          raise       
        end        
    end
    
    assert_equal(5, msgs)
    
  end  
  
end