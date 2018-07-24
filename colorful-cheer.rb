#!/usr/bin/env ruby
require 'eventmachine'
require 'websocket-eventmachine-client'
require 'huey'
require 'configatron'
require_relative 'config.rb'
=begin
Huey.configure do |config|
 config.hue_ip = configatron.bridge
 config.uuid = configatron.user
end
=end

#bulb = Huey::Bulb.find("#{rand(1..4)}")

$msg = nil

def partymode()
end

EM.run do
	ws = WebSocket::EventMachine::Client.connect(:host => 'irc-ws.chat.twitch.tv', :port => 80, :ssl => false)

	ws.onopen do
		puts "Connected"
		ws.send "CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership"
		ws.send "NICK justinfan#{rand(100000..999999)}"

		ws.send "JOIN #dwangoac"
	end

	ws.onmessage do |msg, type|
		if msg.include?('PING') == true
			puts "Received message: #{msg.strip}"

			ws.send "PONG :tmi.twitch.tv"
			ws.pong
		elsif msg.include?('PRIVMSG')
			puts "Received message: #{msg.strip}"

			if msg.include?('bits=500')
				timeloop = Time.new
				until timeloop == timeloop + 60
					#make this loop for a minute.
					lightmsg = $msg.split(';').select{ |word|
						word.include?('color')
					}.to_s

					puts lightmsg
					lightmsg1 = lightmsg.split('=').at(-1).delete('\"]')
					puts lightmsg1
					#bulb.update(rgb: lightmsg1)
					timeloop += 1
				end
			end
		else
			puts "Received message: #{msg.strip}"

		end


	end


	ws.onclose do |code, reason|
		puts "Disconnected with status code: #{code} #{reason}"

	end

	ws.onerror do |error|
		puts "Error: #{error}"

	end

	EventMachine.next_tick do
		puts "tick!"
	end
end



