require 'rubygems'
require 'pho'

# Create the store object
store = Pho::Store.new("http://api.talis.com/stores/space")
# Retrieve the store status as a Status object
status = Pho::Status.read_from_store(store)
# Dump the object to the console
puts status.inspect