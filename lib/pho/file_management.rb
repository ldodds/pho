module Pho
  
  #This module provides support for managing local directories of files and mirroring them
  #into either the metabox or contentbox of a Talis Platform store
  module FileManagement

    #Base class for the management of collections of files
    #
    #A collection is considered to be a directory (and sub-directory) of files. Depending on 
    #the type of collection manager used (e.g. +Pho::FileManagement::FileManager+ or 
    #+Pho::FileManagement::RDFManager+) these may be collections of any kind of file, or just 
    #RDF serialisations.
    #
    #The basic mechanism has support for:
    # * tracking whether a file has been successfully loaded into a store (or not)
    # * identifying all new files, just those that have been successfully stored, or failed
    # * identifying files that have been changed locally since last stored
    # * storage of any of these classes of files either by uploading into the contentbox or 
    #   storing in the metabox
    # * resumable uploads
    # * retrying uploads
    # * traversal across a directory structure to manage a complete set of files
    #
    #Files are tracked locally by keeping some hidden files in the same directory system as the 
    #files being tracked. These are currently all managed in a hidden directory (".pho") that is 
    #automatically created. To access error messages from uploads look for the corresponding "fail file" 
    #for the relevant file. E.g. /foo/file.txt will be tracked in /foo/.pho, and will have either an 
    #OK file (/foo/.pho/file.txt.ok) or a fail file (/foo/.pho/file.txt.fail). 
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
     
      def store_changes(recursive=false)
        changes = changed_files(recursive)
        changes.each do |filename|
          #cleanup tracking files
          f = get_fail_file_for(filename)
          File.delete( f ) if File.exists?(f)
          f = get_ok_file_for(filename)
          File.delete( f ) if File.exists?(f)
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
        Dir.glob( File.join(@dir, "#{pattern}.#{@ok_suffix}") ).each do |file|
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
      
      #Has this file changed (i.e have a newer mtime) than its tracking file
      #Allows files that have been updated in a collection to be easily identified
      #New files (i.e untracked) are always considered to be changed
      def changed?(file)
        if !stored?(file)
          return true
        end
        ok_file = get_ok_file_for(file)
        fail_file = get_fail_file_for(file)
        f = File.new(file)        
        if ( 
            ( File.exists?(ok_file) && f.stat.mtime > File.new(ok_file).stat.mtime ) or
            ( File.exists?(fail_file) && f.stat.mtime > File.new(fail_file).stat.mtime )
           )
          return true
        end        
        return false        
      end
      
      def stored_files(recursive=false)
        stored = Array.new
        list(recursive).each do |file|
          stored << file if stored?(file)
        end
        return stored
      end
      
      def changed_files(recursive=false)
        changed = Array.new
        list(recursive).each do |file|
          changed << file if changed?(file)
        end
        return changed
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
       
      def create_tracking_dir(filename)
        path = filename.split("/")[0..-2].join("/")  
        Dir.mkdir("#{path}/#{TRACKING_DIR}") unless File.exists?("#{path}/#{TRACKING_DIR}")
      end
                
    end
    
  end
  #end file Module  
  
end