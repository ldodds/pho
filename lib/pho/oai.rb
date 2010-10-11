module Pho

  #OAI-PMH Support
  module OAI
  
    #Access basic store statistics via the OAI interface    
    class Statistics
      
      #Datestamp of last updated record in the store
      #
      #This reads the OAI-PMH interface and retrieves the datestamp of the most
      #recently updated item
      def Statistics.last_updated(store)
        records = Records.read_from_store(store)
        return records.records[0].datestamp
      end
      
      #Number of entities in the store. This includes all resources in both the 
      #metabox AND the contentbox
      def Statistics.num_of_entities(store)
        records = Records.read_from_store(store)
        if records.resumption_token != nil
          return records.list_size
        else 
          return records.records.length
        end
      end
      
    end
    
    class Record
      
        attr_reader :identifier
        attr_reader :datestamp
        
        def initialize(identifier, datestamp)
          @identifier = identifier
          @datestamp = datestamp
        end  
        
    end
    
    #Collection of records
    class Records
    
      attr_reader :response_date, :from, :to, :records, :resumption_token, :list_size, :cursor
      
      def initialize(responseDate, from, to, records=[], token=nil, list_size=nil, cursor=nil)
        @response_date = responseDate
        @from = from
        @to = to
        @records = records
        @resumption_token = token
        @list_size = list_size
        @cursor = cursor
      end
      
      def Records.parse(response)
        doc = REXML::Document.new(response)
        if doc.root.get_elements("error")[0] != nil
          code = doc.root.get_elements("error")[0].attributes["code"]
          if code == "noRecordsMatch"
            return nil
          else
            raise "Unable to list records: #{code}, #{doc.root.get_elements("error")[0].text}"
          end          
        end
        records = []        
        responseDate = doc.root.get_elements("responseDate")[0].text
        from = doc.root.get_elements("request")[0].attributes["from"]
        from = DateTime.parse( from ) unless from == nil          
        to = doc.root.get_elements("request")[0].attributes["until"]
        to = DateTime.parse( to ) unless to == nil 
        REXML::XPath.each( doc.root,  "//oai:header", {"oai" => "http://www.openarchives.org/OAI/2.0/"} ) do |header|
         uri = header.get_elements("identifier")[0].text
         datestamp = header.get_elements("datestamp")[0].text
         records << Record.new(uri, DateTime.parse( datestamp ) )
        end
        resumption_token = doc.root.get_elements("//resumptionToken")[0]
        if resumption_token != nil
            token = resumption_token.text
            list_size = resumption_token.attributes["completeListSize"].to_i if resumption_token.attributes["completeListSize"] != nil 
            cursor = resumption_token.attributes["cursor"].to_i if resumption_token.attributes["cursor"] != nil
        end
        return Records.new(DateTime.parse(responseDate), from, to, records, token, list_size, cursor)   
      end
      
      #List records from a store
      def Records.read_from_store(store, from=nil, to=nil, resumption_token=nil)
        resp = store.list_records(from, to, resumption_token)
        if resp.status != 200
          raise "Unable to list records"
        end
        return parse(resp.content)
      end
      
      #Fetch the next list of records from a store, using a resumption token
      #
      #Returns nil if there are no records to retrieve. Can be used as a simple iterator, e.g:
      #
      # records = store.list_records
      # while records != nil
      #   #do something with retrieved records
      #   records = Records.read_next_records(store, records.resumption_token)
      # end
      #
      #store:: the store
      #resumption_token:: previously retrieved resumption_token
      def Records.read_next_records(store, resumption_token)
        #list is already complete
        if resumption_token == nil
          return nil
        end
        return Records.read_from_store(store, nil, nil, token)
      end
            
    end
    
  end  
  
end