# Use OpenCalais to find entities in a document specified on the command-line, then store the results
# in a Platform store
#
# Set the following environment variables:
#
# TALIS_USER:: username on Platform
# TALIS_PASS:: password
# TALIS_STORE:: store in which data will be stored
# CALAIS_KEY:: Calais license key
#
#sudo apt-get install libcurl3-dev
#sudo gem install curb
#sudo gem install calais
#
require 'rubygems'
require 'pho'
require 'calais'

store = Pho::Store.new(ENV["TALIS_STORE"], ENV["TALIS_USER"], ENV["TALIS_PASS"])
content = File.new(ARGV[0]).read()
resp = Calais.enlighten( :content => content, :content_type => :text, :license_id => ENV["CALAIS_KEY"])
resp = store.store_data(resp)
puts resp.status
