module Pho
  
  module FileManagement

    class AbstractFileManager
    
      attr_reader :dir
      attr_reader :store
        
      OK = "ok"
      FAIL = "fail"
      TRACKING_DIR = ".pho"
      
      def initialize(store, dir, ok_suffix=OK, fail_suffix=FAIL)
        @store = store
        @dir = dir
        @ok_suffix = ok_suffix
        @fail_suffix = fail_suffix
      end
  
      #Store all files that match the file name in directory
      def store(recursive=false)
        files_to_store = new_files(recursive)
        files_to_store.each do |filename|
          file = File.new(filename)
          store_file(file, filename)
        end
      end
  
      #Retry anything known to have failed
      def retry_failures(recursive=false)
        retries = failures(recursive)
        retries.each do |filename|
          File.delete( get_fail_file_for(filename) )
          #store it
          file = File.new(filename)
          store_file(file, filename)      
        end
      end
            
      #Reset the directory to clear out any previous statuses
      def reset(recursive=false)
        if recursive
          pattern = "**/#{TRACKING_DIR}/*"
        else
          pattern = "/#{TRACKING_DIR}/*"
        end        
        Dir.glob( File.join(@dir, "#{pattern}.#{@fail_suffix}") ).each do |file|
          File.delete(file)
        end
        Dir.glob( File.join(@dir, "/#{TRACKING_DIR}/*.#{@ok_suffix}") ).each do |file|
          File.delete(file)
        end         
      end
      
      #returns true if there is a fail or ok file, false otherwise
      def stored?(file)
        ok_file = get_ok_file_for(file)
        fail_file = get_fail_file_for(file)        
        if ( File.exists?(ok_file) or File.exists?(fail_file) )
          return true
        end        
        return false
      end     
      
      #List any new files in the directory
      def new_files(recursive=false)
        newfiles = Array.new
        list(recursive).each do |file|
          newfiles << file if !stored?(file)            
        end
        return newfiles
      end
                     
      #List failures
      def failures(recursive=false)
        fails = Array.new
        list(recursive).each do |file|
          fails << file if File.exists?( get_fail_file_for(file) )
        end
        return fails
      end
      
      #List successes
      def successes(recursive=false)
        successes = Array.new
        list(recursive).each do |file|
          successes << file if File.exists?( get_ok_file_for(file) )
        end
        return successes
      end
            
      #Summarize the state of the collection to the provided IO object
      #Creates a simple report
      def summary(recursive=false)
         failures = failures(recursive)
         successes = successes(recursive)
         newfiles = new_files(recursive)
         total = failures.size + successes.size + newfiles.size
         summary = "#{@dir} #{recursive ? " and sub-directories" : ""} contains #{total} files: #{successes.size} stored, #{failures.size} failed, #{newfiles.size} new"
         return summary     
      end
      
      def get_fail_file_for(filename)
        relative_path = filename.gsub(@dir, "")
        base = File.basename(filename)
        relative_path = relative_path.gsub(base, "#{TRACKING_DIR}/#{base}")
        return "#{@dir}#{relative_path}.#{@fail_suffix}"              
      end
      
      def get_ok_file_for(filename)
        relative_path = filename.gsub(@dir, "")
        base = File.basename(filename)
        relative_path = relative_path.gsub(base, "#{TRACKING_DIR}/#{base}")
        return "#{@dir}#{relative_path}.#{@ok_suffix}"              
      end
                 
    end
    
  end
  #end file Module  
  
end