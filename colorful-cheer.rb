#!/usr/bin/env ruby
require 'huey'

require 'rest-client'
require 'usleep'
require 'oj'
require 'configatron'
require_relative 'config.rb'

#Lets make huey use our new user
Huey.configure do |config|
  config.hue_ip = configatron.brige
  config.uuid = configatron.user
end

bulb = Huey::Bulb.find(3)
bulb.alert!
loop do
  bulb.update(rgb: '#ff0000')
  sleep 1.0/4.0
  bulb.update(rgb: '#00ff00')
  sleep 1.0/4.0
  bulb.update(rgb: '#0000ff')
  sleep 1.0/4.0
end
