module Pho

# TODO: assigning identifiers via changesets (Blank nodes on subject of change and subject)  
# TODO: assigning identifiers to a changeset docs
# TODO: linking together changesets using either nodeID or an identifier
      
  require 'uri'
  
  #Module organizing classes related to Changeset handling.
  module Update

    #Base class capturing data relating to a reified RDF triple described in a Changeset
    class Statement
      
        #URI of subject
        attr_reader :subject
        #URI of predicate
        attr_reader :predicate
        #Object value. May be uri or literal
        attr_reader :object

        # Create a Statement referring to a literal. Can have one of lang or datatype but not both
        # 
        #  subject:: URI of subject of triple
        #  predicate:: URI of predicate of triple
        #  object:: literal value
        #  lang:: language for literal
        #  datatype:: datatype for literal      
        def Statement.create_literal(subject, predicate, object, lang=nil, datatype=nil)
          return LiteralStatement.new(subject, predicate, object, lang, datatype)
        end

        # Create a Statement referring to a resource
        # 
        #  subject:: URI of subject of triple
        #  predicate:: URI of predicate of triple
        #  object:: resource uri
        def Statement.create_resource(subject, predicate, object)
            return ResourceStatement.new(subject, predicate, object)
        end
        
        #Create an RDF/XML fragment describing this Statement        
        def to_rdf()
          rdf = "<rdf:Statement>"
          rdf << write_subject()
          rdf << "  <rdf:predicate rdf:resource=\"#{@predicate}\"/>"
          rdf << write_object()
          rdf << "</rdf:Statement>"
          return rdf          
        end
               
        private
       
         def write_subject()
           return "  <rdf:subject rdf:resource=\"#{@subject}\"/>"
         end
         
         #  subject:: URI of subject of triple
         #  predicate:: URI of predicate of triple
         #  object:: object value of triple (may be URI or literal)
         def initialize(subject, predicate, object)
           @subject = subject
           @predicate = predicate
           @object = object
         end
       
         class << self
           protected :new
         end
    end

    class LiteralStatement < Statement
      
       #Language for literals
       attr_reader :language
       #Datatype for literals
       attr_reader :datatype
      
       # Create a Statement referring to a literal. Can have one of lang or datatype but not both
       # 
       #  subject:: URI of subject of triple
       #  predicate:: URI of predicate of triple
       #  object:: literal value
       #  lang:: language for literal
       #  datatype:: datatype for literal      
       def initialize(subject, predicate, object, language=nil, datatype=nil)
         super(subject, predicate, object)
         if language != nil && datatype != nil
           raise "Cannot specify both language and datatype for a literal"
         end         
         @language = language
         @datatype = datatype
       end
       
       def ==(other)
        if other == nil
          return false
        end
        return @subject == other.subject &&
               @predicate == other.predicate &&
               @object == other.object &&
               @lang == other.language &&
               @datatype == other.datatype
       end
       
       protected
        def write_object()
          tag = ""
          if @datatype != nil
            tag = "<rdf:object rdf:datatype=\"#{@datatype}\">"
          elsif @language != nil
            tag = "<rdf:object xml:lang=\"#{@language}\">"
          else
            tag = "<rdf:object>" 
          end
          text = @object.gsub("&", "&amp;")
          tag << "#{text}</rdf:object>"          
          return tag
        end
    end

    class ResourceStatement < Statement
       # Create a Statement referring to a resource
       # 
       #  subject:: URI of subject of triple
       #  predicate:: URI of predicate of triple
       #  object:: resource uri
       def initialize(subject, predicate, object)
        super(subject, predicate, object)
       end
       
       def ==(other)
        if other == nil
          return false
        end
        return @subject == other.subject &&
              @predicate == other.predicate &&
              @object == other.object
       end
      
       protected
        def write_subject()
           return "  <rdf:subject rdf:resource=\"#{@subject}\"/>"
        end
       
        def write_object()
          "<rdf:object rdf:resource=\"#{@object}\"/>"
        end
    end

    #The Changesets class provides utility methods for manipulating and generating
    #collections of Changeset objects     
    class Changesets
      
      #Convert an array of changesets into an RDF/XML document
      #
      # changesets:: an array of changesets
      def Changesets.all_to_rdf(changesets)
        rdf = "<rdf:RDF xmlns:cs=\"http://purl.org/vocab/changeset/schema#\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">"
        changesets.each do |cs|
          rdf << cs.to_rdf(false)
        end
        rdf << "</rdf:RDF>"
      end
      
      #Submit an array of changests to the Platform. After first converting them to
      #an RDF/XML document.  
      #
      # Note that this submits all of the changessets in a single request to the Platform
      # If the changeset is too large then it may be rejected. Similarly the Platform may 
      # respond with a 202 Accepted status if the data is to be processed asynchronously; 
      # again that depends on the size of the changes.
      #
      # changesets:: an array of changesets
      # store:: the store to submit the changesets to
      # versioned:: whether this is a versioned changed. Versioned Changesets must have 
      # change_reason and creator_name properties.
      def Changesets.submit_all(changesets, store, versioned=false)
          rdf = all_to_rdf(changesets)
          store.submit_changeset(rdf, versioned)
      end
      
      # Build a changeset by comparing two Ruby hashes
      #
      # subject_of_change:: URI of resource being changed
      # before_model:: hash containing RDF before change. Organized as RDF/JSON
      # after_model:: hash containing RDF after change. Organized as RDF/JSON
      #def Changesets.build(before_model, after_model)
      #  
      #end            
      
    end
                    
    #Models a Changeset: a delta to an RDF graph
    #
    #The RDF Schema for Changesets can be found at:
    #  http://vocab.org/changeset/schema
    #
    #Further reading:
    #  http://n2.talis.com/wiki/Changesets
    #
    #The Platform Changeset protocol is described at:
    #  http://n2.talis.com/wiki/Changeset_Protocol
    #
    #Processing of batch changesets is described at:
    #  http://n2.talis.com/wiki/Metabox
    #
    class Changeset
      
      #URI of the subject of change for this changeset
      attr_reader :subject_of_change
      #Creator name
      attr_accessor :creator_name
      #Reason for the change being made
      attr_accessor :change_reason
            
      #Constructor. Parameter should be the URI of the subject of change
      #
      # subject_of_change:: the URI of the resource being changed
      # creator_name:: the name of the creator of this change (optional)
      # change_reason:: the reason for the change (optional)
      def initialize(subject_of_change, creator_name=nil, change_reason=nil)
        u = URI.parse(subject_of_change)
        #this should catch literals
        if u.scheme() == nil
          raise URI::InvalidURIError.new("Invalid URI")
        end
        @subject_of_change = subject_of_change
        @creator_name = creator_name
        @change_reason = change_reason
        @additions = Array.new
        @removals = Array.new
        yield self if block_given?
      end
      
      def to_s
        return to_rdf
      end
      
      #Serialize this changeset as RDF/XML suitable for submitting to the Platform.
      def to_rdf(include_root=true)
        rdf = ""
        if include_root
          rdf << "<rdf:RDF xmlns:cs=\"http://purl.org/vocab/changeset/schema#\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">"  
        end
        
        rdf << " <cs:ChangeSet>"
        rdf << "  <cs:subjectOfChange rdf:resource=\"#{@subject_of_change}\"/>"
        if @creator_name
          rdf << "  <cs:creatorName>#{@creator_name}</cs:creatorName>"
        end
        if @change_reason
          rdf << "  <cs:changeReason>#{@change_reason}</cs:changeReason>"
        end
        @additions.each do |add|
            rdf << "  <cs:addition>"
            rdf << add.to_rdf
            rdf << "  </cs:addition>"                                
        end
        @removals.each do |remove|
          rdf << "  <cs:removal>"
          rdf << remove.to_rdf
          rdf << "  </cs:removal>"                                
        end
        
        rdf << " </cs:ChangeSet>"
        
        if include_root
          rdf << "</rdf:RDF>"  
        end
        
        return rdf        
      end

      #Return the Statement describing the addition in this Changeset
      def additions()
        return @additions
      end
      
      #Include a Statement in the Changeset as an addition 
      def add_addition(statement)
        if statement.subject != @subject_of_change
          raise "Subject of statement must match subject of change of changeset"
        end
        @additions << statement
      end
      
      #Add an array of statements as additions
      def add_additions(statements)
        statements.each do |statement|
          add_addition(statement)
        end
      end
  
      #Return the list of Statements describing the removals in this Changeset
      def removals()
        return @removals
      end
      
      #Include a Statement in the Changeset as a removal
      def add_removal(statement)
        if statement.subject != @subject_of_change
          raise "Subject of statement must match subject of change of changeset"
        end
        @removals << statement
      end

      #Add an array of statements as removals
      def add_removals(statements)
        statements.each do |statement|
          add_removal(statement)
        end
      end
            
      #Submit this changeset to the specified store
      #
      # store:: the store to which the changeset should be applied
      def submit(store, versioned=false)
        return store.submit_changeset(self.to_rdf, versioned)
      end

    #end changeset   
    end
   
    #Utility methods for making changes to graphs via Changesets
    class ChangesetHelper
    
      def ChangesetHelper.update_literal(store, subject, predicate, old_value, new_value, old_lang=nil, old_datatype=nil, 
          new_lang=nil, new_datatype=nil, creator_name=nil, change_reason=nil, versioned=false)
        cs = Changeset.new(subject, creator_name, change_reason)
        old = Statement.create_literal(subject, predicate, old_value, old_lang, old_datatype)
        new = Statement.create_literal(subject, predicate, new_value, new_lang, new_datatype)
        cs.add_removal(old)
        cs.add_addition(new)
        return cs.submit(store, versioned)
      end
      
      
    end    
    
  #end module                   
  end

end