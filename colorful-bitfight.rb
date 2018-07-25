#!/usr/bin/env ruby
require 'eventmachine'
require 'websocket-eventmachine-client'
require 'huey'
require 'color_converter'
require 'configatron'
require_relative 'config.rb'

$red = 127
$blue = 127
$green = 127


Huey.configure do |config|
	config.hue_ip = configatron.bridge
	config.uuid = configatron.user
end


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
			#puts "Received message: #{msg.strip}"


			if msg.include?('red')
				redmsg = msg.split(' ')
				redmsg1 = redmsg[0].split(';').select{ |word|
					word.include?('bits=')
				}.to_s

				redmsg2 = redmsg1.delete('\[\]\"').split('=').at(-1).to_i
				$red = $red + redmsg2
				$green = $green - redmsg2
				$blue = $blue - redmsg2

				hexcolor = ColorConverter.hex($red.clamp(0, 255), $green.clamp(0, 255), $blue.clamp(0, 255))
				Huey::Bulb.all.update(rgb: hexcolor)
				print hexcolor

			elsif msg.include?('green')
				grnmsg = msg.split(' ')
				grnmsg1 = grnmsg[0].split(';').select{ |word|
					word.include?('bits=')
				}.to_s

				grnmsg2 = grnmsg1.delete('\[\]\"').split('=').at(-1).to_i
				$red = $red + grnmsg2
				$green = $green - grnmsg2
				$blue = $blue - grnmsg2

				hexcolor = ColorConverter.hex($red.clamp(0, 255), $green.clamp(0, 255), $blue.clamp(0, 255))
				Huey::Bulb.all.update(rgb: hexcolor)
				print hexcolor

			elsif msg.include?('blue')
				blumsg = msg.split(' ')
				blumsg1 = blumsg[0].split(';').select{ |word|
					word.include?('bits=')
				}.to_s

				blumsg2 = blumsg1.delete('\[\]\"').split('=').at(-1).to_i
				$red = $red + blumsg2
				$green = $green - blumsg2
				$blue = $blue - blumsg2


				hexcolor = ColorConverter.hex($red.clamp(0, 255), $green.clamp(0, 255), $blue.clamp(0, 255))
				Huey::Bulb.all.update(rgb: hexcolor)
				print hexcolor
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



