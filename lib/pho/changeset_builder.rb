module Pho
      
  require 'uri'
  
  #Module organizing classes related to Changeset handling.
  module Update
    
    #Utility class providing methods for building Changesets from triple hashes
    class ChangesetBuilder
    
      #Build a batch changeset
      #
      #This method is suitable for building an array of changesets that describe changes made to a
      #number of different resources.
      #
      #Returns an array of Changeset objects
      #
      # before:: resource hash describing current state of the resource
      # after:: resource hash describing updated state of the resource
      # creator_name:: name of the creator of the changes
      # change_reason:: description of why the changes are being made      
      def ChangesetBuilder.build_batch(before, after, creator_name=nil, change_reason=nil)

        removals = Pho::ResourceHash::SetAlgebra.minus(before, after)
        additions = Pho::ResourceHash::SetAlgebra.minus(after, before)
        
        batch = Array.new
        
        removals.each do |uri, properties|
          cs = Pho::Update::Changeset.new(uri, creator_name, change_reason) do |cs|
              cs.add_removals( create_statements_for_uri(uri, properties) )
              if additions.has_key?(uri)
                cs.add_additions( create_statements_for_uri(uri, additions[uri] ) )
                additions.delete(uri)
              end      
          end
          batch << cs
        end
        
        if !additions.empty?
          additions.each do |uri, properties|
            cs = Pho::Update::Changeset.new(uri, creator_name, change_reason) do |cs|
                cs.add_additions( create_statements_for_uri(uri, properties) )
            end
            batch << cs            
          end
        end
        
        return batch
        
      end
      
      #Build a single changeset
      #
      #This method is suitable for building changesets that describe changes made to a single resource
      #If the before/after hashes contain data for other subjects, then an error will be thrown.
      #
      #The method will return a single Changeset object.
      #
      # subject_of_change:: uri of the resource being updated
      # before:: resource hash describing current state of the resource
      # after:: resource hash describing updated state of the resource
      # creator_name:: name of the creator of the changes
      # change_reason:: description of why the changes are being made
      def ChangesetBuilder.build(subject_of_change, before, after, creator_name=nil, change_reason=nil)
        removals = Pho::ResourceHash::SetAlgebra.minus(before, after)
        additions = Pho::ResourceHash::SetAlgebra.minus(after, before)
        
        cs = Pho::Update::Changeset.new(subject_of_change, creator_name, change_reason) do |cs|
            cs.add_removals( create_statements(removals) )
            cs.add_additions( create_statements(additions) )      
        end
        
        return cs
        
      end  
      
      #Takes a resource hash and serializes it as an array of Pho::Update::Statement objects
      #
      # triples:: a resource hash, conforming to RDF-in-JSON structure
      def ChangesetBuilder.create_statements(triples)
        statements = Array.new
        triples.each do |uri, properties|
           statements += create_statements_for_uri(uri, properties)
        end
        return statements
      end

      #Create statements for a specific uri, using predicate-object values in 
      #the provided properties hash
      #
      # uri:: subject of change
      # properties:: hash of predicate-object values
      def ChangesetBuilder.create_statements_for_uri(uri, properties)
        statements = Array.new
        properties.each do |predicate, val_array|
          val_array.each do |value|
            s = nil
            if value["type"] == "literal"
                s = Pho::Update::Statement.create_literal(uri, predicate, value["value"], value["lang"], value["datatype"])
            else
                #TODO bnodes?
                s = Pho::Update::Statement.create_resource(uri, predicate, value["value"])
            end
            if s != nil
              statements << s
            end
          end
        end
        return statements        
      end      
      
    end
    
  end
  
end
  