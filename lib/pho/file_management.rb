module Pho
  
  module FileManagement

    #TODO: move files into hidden directory
    class AbstractFileManager
    
      attr_reader :dir
      attr_reader :store
        
      OK = "ok".freeze
      FAIL = "fail".freeze
      
      def initialize(store, dir, ok_suffix=OK, fail_suffix=FAIL, sleep=1)
        @store = store
        @dir = dir
        @sleep = sleep
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
      def retry_failures()
        retries = failures()
        retries.each do |filename|
          File.delete( get_fail_file_for(filename) )
          #store it
          file = File.new(filename)
          store_file(file, filename)      
        end
      end
            
      #Reset the directory to clear out any previous statuses
      def reset()
        Dir.glob( File.join(@dir, "*.#{@fail_suffix}") ).each do |file|
          File.delete(file)
        end
        Dir.glob( File.join(@dir, "*.#{@ok_suffix}") ).each do |file|
          File.delete(file)
        end         
      end
           
      #List any new files in the directory
      def new_files(recursive=false)
        newfiles = Array.new
        list(recursive).each do |file|
          
          ok_file = get_ok_file_for(file)
          fail_file = get_fail_file_for(file)
          if !( File.exists?(ok_file) or File.exists?(fail_file) )
            newfiles << file          
          end
            
        end
        return newfiles
      end
                     
      #List failures
      def failures(recursive=false)
        fails = Array.new
        list(recursive).each do |file|
          if File.extname(file) != ".#{@fail_suffix}" && File.extname(file) != ".#{@ok_suffix}"
            fails << file if File.exists?( get_fail_file_for(file) )  
          end          
        end
        return fails
      end
      
      #List successes
      def successes(recursive=false)
        successes = Array.new
        list(recursive).each do |file|
          if File.extname(file) != ".#{@fail_suffix}" && File.extname(file) != ".#{@ok_suffix}"
             successes << file if File.exists?( get_ok_file_for(file) )
          end
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
        ext = File.extname(filename)
        return filename.gsub(/#{ext}$/, ".#{@fail_suffix}")              
      end
      
      def get_ok_file_for(filename)
        ext = File.extname(filename)        
        return filename.gsub(/#{ext}$/, ".#{@ok_suffix}")
      end
                 
    end
    
  end
  #end file Module  
  
end