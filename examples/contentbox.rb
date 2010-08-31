require 'rubygems'
require 'pho'

# Create the store object
store = Pho::Store.new("http://api.talis.com/stores/ldodds-dev1", "ldodds", "XXXXXXX")

# Using StringIO object here, but could more usually provide a File object
data = StringIO.new("Some data to store")

puts "Uploading item..."
resp = store.upload_item(data, "text/plain", "/items/test.txt")

puts "Status code after storage is: #{resp.status}"

puts "Retrieving data..."
resp = store.get_item("http://api.talis.com/stores/ldodds-dev1/items/test.txt")

puts "Status code after retrieval is #{resp.status}"
# Should output "Some data to store"
puts "Retrieved data is: #{resp.content}"

puts "Deleting item..."
resp = store.delete_item("/items/test.txt")

puts "Status code after deletion is #{resp.status}"

puts "Retrieving data..."
resp = store.get_item("http://api.talis.com/stores/ldodds-dev1/items/test.txt")

puts "Status code after deletion is: #{resp.status}"