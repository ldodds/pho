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
                writer << stmts
                stmts = []
              end              
            end
          end
        end
        if !stmts.empty?
          RDF::Writer.open( File.join(@dir, "#{basename}_#{count}.nt") ) do |writer|
            writer << stmts
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
      #where necessary.      
      def Util.prepare_platform_upload(store, src_dir, collection_dir, 
          triples=FileSplitter::DEFAULT_CHUNK_SIZE)
          
          handler = BNodeRewritingHandler.new( store.build_uri("/items") )
          splitter = FileSplitter.new(collection_dir, triples, handler )
          
          formats = [ ["*.rdf", :rdfxml], ["*.nt", :ntriples], ["*.ttl", :turtle] ]
          formats.each do |format|
            
            to_split = []
            files = Dir.glob( File.join(src_dir, format[0] ) )
            files.each do |file|
              if File.size(file) > 2000000
                to_split << file
              else
                File.copy(file, collection_dir)
              end 
            end
            splitter.split_files(to_split, format[1] )
            
          end
          
      end
      
    end
  end
end