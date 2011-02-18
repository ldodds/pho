module Pho
  
  module FileManagement
    
    #Default statement handler, does nothing
    class StatementHandler
      def handle(statement)
        return statement
      end
    end
    
    #Remove bnodes from the input data by assigning URIs to them
    #
    #This implementation generates a simple hexdigest based on the node id
    #and uses that to construct a uri based on a base uri provided in the 
    #constructor
    class BNodeRewritingHandler
      # base:: base uri for URIs generated for blank nodes
      def initialize(base)
        @base = base
      end
      
      def handle(statement)
        if !statement.has_blank_nodes?
          return statement
        end
        subject = statement.subject
        if subject.anonymous?
          subject = RDF::URI.new( assign_uri(subject) )
        end
        object = statement.object
        if object.anonymous?
          object = RDF::URI.new( assign_uri(object) )
        end
        return RDF::Statement.new(subject, statement.predicate, object)
      end
      
      #FIXME semantics for this is wrong if nodeIds are reused across
      #datasets
      def assign_uri(node)
        return "#{@base}/#{Digest::MD5.hexdigest( node.id )}#self"
      end
      
    end
    
    #Supports splitting RDF data files into smaller chunks of ntriples     
    class FileSplitter
      
      attr_reader :dir, :triples, :handler
      
      DEFAULT_CHUNK_SIZE = 10000
      
      #Create a file splitter instance
      #
      #  dir:: temporary directory into which split files should be written
      #  triples:: number of triples per split file
      #  handler:: statement handler to allow pre-processing of statements
      def initialize(dir="/tmp", triples=DEFAULT_CHUNK_SIZE, 
          handler=Pho::FileManagement::StatementHandler.new)
        @dir = dir
        @triples = triples
        @handler = handler
      end
            
      #Split a single file, in any parseable RDF format into smaller
      #chunks of ntriples. Chunked files are stored in default temporary
      #directory for this instance
      #
      #  filename:: name of the file to split
      #  format:: input format, default is :ntriples
      def split_file(filename, format=:ntriples)
        
        basename = File.basename(filename, ".#{filename.split(".").last}")
        count = 0
        stmts = []
        RDF::Reader.for(format).new(File.new(filename)) do |reader|
          reader.each_statement do |statement|            
            count += 1
            stmts << @handler.handle( statement ) 
            if count % @triples == 0
              RDF::Writer.open( File.join(@dir, "#{basename}_#{count}.nt") ) do |writer|
                stmts.each do |s|
                  writer << s
                end
              end              
              stmts = []              
            end
          end
        end
        if !stmts.empty?
          RDF::Writer.open( File.join(@dir, "#{basename}_#{count}.nt") ) do |writer|
            stmts.each do |s|
              writer << s
            end
          end
        end
      end

      #Split a list of files into smaller chunks
      #
      #  list_of_filenames:: array of filenames
      #  format:: format of the files, default is :ntriples      
      def split_files(list_of_filenames, format=:ntriples)
        list_of_filenames.each do |name|
          split_file(name, format)
        end
      end  
                
    end
        
    class Util

      #Take a directory of files, copy them to temporary directory, splitting
      #where necessary, in preparation for uploading to a platform store.
      #
      #Source directory is scanned for ntriple, turtle and RDF/XML files. All of 
      #these are automatically chunked into 10,000 triple chunks and re-serialized 
      #as ntriples
      #
      #BNodes are automatically re-written to full uris.
      #
      #  store:: Pho::Store into which data will be posted. Used to normalizing bnodes
      #  src_dir:: directory containing source data.      
      def Util.prepare_platform_upload(store, src_dir, collection_dir, 
          triples=FileSplitter::DEFAULT_CHUNK_SIZE)
          
          handler = BNodeRewritingHandler.new( store.build_uri("/items") )
          splitter = FileSplitter.new(collection_dir, triples, handler )
          
          formats = [ ["*.rdf", :rdfxml], ["*.nt", :ntriples], ["*.ttl", :turtle] ]
          formats.each do |format|
            
            files = Dir.glob( File.join(src_dir, format[0] ) )
            splitter.split_files(files, format[1] )
            
          end
          return true
          
      end
      
      #Prepares a batch of files for uploading into the platform, then posts
      #that collection to the designated store
      #
      #Returns an RDFManager instance that can be inspected to check for successes
      def Util.prepare_and_store_upload(store, src_dir, collection_dir, 
          triples=FileSplitter::DEFAULT_CHUNK_SIZE)
          
        prepare_platform_upload(store, src_dir, collection_dir)
        collection = Pho::FileManagement::RDFManager.new(store, collection_dir)
        collection.store()
        return collection
      end
      
    end
  end
end