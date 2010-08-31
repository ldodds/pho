module Pho

  #Can only read data
  READ_ONLY = "http://schemas.talis.com/2006/bigfoot/statuses#read-only".freeze
  #Can read and write data
  READ_WRITE = "http://schemas.talis.com/2006/bigfoot/statuses#read-write".freeze
  #Cannot access the store
  UNAVAILABLE = "http://schemas.talis.com/2006/bigfoot/statuses#unavailable".freeze
        
  #Captures status information relating to a store
  class Status
      
    #Interval before status should be requested again.
    attr_reader :retry_interval
    
    #Status message
    attr_reader :status_message
    
    #Current access mode uri
    #
    #This will be one of Pho::READ_ONLY, Pho::READ_WRITE, or Pho::UNAVAILABLE. Use the 
    #readable and writeable methods to test for the different modes
    attr_reader :access_mode
    
    def initialize(retry_interval, status_message, access_mode)
      @retry_interval = retry_interval
      @status_message = status_message
      @access_mode = access_mode
    end
    
    #Create a Status object by reading the response from a store access status request
    #
    #The code parses the JSON output from the Platform API to create a Status object.
    #
    #store:: the store whose status is to be read
    def Status.read_from_store(store)
      response = store.get_status()
      if (response.status != 200)
        raise "Cannot read store status"
      end
      
      u = store.build_uri("/config/access-status")
      json = JSON.parse( response.content )
      retry_interval = json[u]["http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#retryInterval"][0]["value"]
      status_message = json[u]["http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#statusMessage"][0]["value"]
      access_mode = json[u]["http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#accessMode"][0]["value"]
      
      state = Status.new(retry_interval.to_i, status_message, access_mode)
      return state
          
    end
    
    #Is the store readable?
    def readable?
      return @access_mode != Pho::UNAVAILABLE
    end

    #Is the store writeable?
    def writeable?
      return @access_mode == Pho::READ_WRITE
    end
        
  end
  
end