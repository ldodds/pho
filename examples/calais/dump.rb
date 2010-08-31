# Use OpenCalais to find entities in a document specified on the command-line, then dump the result to the command-line
#
# Set the following environment variables:
#
# CALAIS_KEY:: Calais license key
#
#sudo apt-get install libcurl3-dev
#sudo gem install curb
#sudo gem install calais
#
require 'rubygems'
require 'pho'
require 'calais'

content = File.new(ARGV[0]).read()
resp = Calais.enlighten( :content => content, :content_type => :text, :license_id => ENV["CALAIS_KEY"])
puts resp
