#!/usr/bin/env ruby
# frozen_string_literal: true

require 'configatron'
require 'rest-client'
require 'tty-prompt'
require 'json'
require_relative 'config/config.rb'

# rubocop:disable Metrics/LineLength, Style/BracesAroundHashParameters

prompt = TTY::Prompt.new

name = prompt.ask('What would you like the app to be called on your Hue bridge?') do |q|
  q.required true
  q.default 'HueFighter'
end

prompt.keypress('To use HueFighter you will need to pair with your Hue Bridge. Press the button on your bridge and then press enter when ready.', keys: [:return], timeout: 30)

response = RestClient.post "http://#{configatron.bridge}/api", { "devicetype": name.to_s }.to_json, { content_type: :json, accept: :json }

body = JSON.parse(response)[0]

if body.fetch('error').fetch('description')
  puts body.fetch('error').fetch('description')
elsif body.fetch('success').fetch('username')
  puts 'Please add this username to your config.rb file'
  puts body.fetch('success').fetch('username')

end

# rubocop:enable Metrics/LineLength, Style/BracesAroundHashParameters
