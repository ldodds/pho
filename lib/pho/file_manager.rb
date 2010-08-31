module Pho

  require 'mime/types'
    
  module FileManagement

    class FileManager < AbstractFileManager
   
      attr_reader :base
      
      def initialize(store, dir, base = nil, ok_suffix=OK, fail_suffix=FAIL, sleep=1)
        super(store, dir, ok_suffix, fail_suffix, sleep)
        @base = base
      end

      #List files being managed, i.e. everything not .ok or .fail
      def list(recursive=false)          
          files = []
          if recursive
            pattern = "**/*"
          else
            pattern = "*"
          end
          Dir.glob( File.join(@dir, pattern) ) do |file|
            if File.extname(file) != ".#{@ok_suffix}" && File.extname(file) != ".#{@fail_suffix}" && !File.directory?(file)
              files << file
            end
          end  
          return files
      end
           
      def FileManager.name_for_file(dir, file, base=nil)
        uri = file.path.gsub(dir, "")
        uri = "#{base}#{uri}" if base != nil
        return uri
      end                  
      
      protected
  
      def store_file(file, filename)
        uri = FileManager.name_for_file(@dir, file, @base)
        response = @store.upload_item(file, MIME::Types.type_for(filename)[0].to_s, uri )
        if (response.status < 300 )
          File.open(get_ok_file_for(filename), "w") do |file|
            file.print( "OK" )            
          end
        else
          File.open(get_fail_file_for(filename), "w") do |file|
            YAML::dump(response, file)
          end            
        end      
      end  
         
    end
    
  end
end