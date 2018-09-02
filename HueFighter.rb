#!/usr/bin/env ruby2.5
require 'eventmachine'
require 'websocket-eventmachine-client'
require 'huey'
require 'color_converter'
require 'configatron'
require 'securerandom'
require_relative 'config.rb'

$red = 127
$green = 127
$blue = 127


Huey.configure do |config|
 config.hue_ip = configatron.bridge
 config.uuid = configatron.user
end


@group = Huey::Group.new(Huey::Bulb.find(1), Huey::Bulb.find(2))
@group.name = 'HueFighter'
@group.save
@group.on = true
@group.update(rgb: "#{configatron.basecolor}")


@i = 0
@r = 0
$hex_col = nil
$$hex_out
$msg = nil

def partymode()
	loop do
		break if @i == 5 # Let's leave our loop
		color = SecureRandom.hex(3)
		puts "Set color to ##{color} on light #{rand(1..4)}"
		Huey::Bulb.all.update(rgb: "##{color}")
		@i += 1
		sleep 1
		
	end
end

def resetlights()
	loop do
		break if @r == 1
		puts "Party mode over reseting color to #{$hex_out}"
		@group.update(rgb: $hex_out)
		@r += 1
	end
end


EM.run do
	ws = WebSocket::EventMachine::Client.connect(:host => 'irc-ws.chat.twitch.tv', :port => 80, :ssl => false)

	ws.onopen do
		puts "Connected"
		ws.send "CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership"
		ws.send "NICK justinfan#{rand(100000..999999)}"

		ws.send "JOIN ##{configatron.channel}"


	end

	ws.onmessage do |msg, type|
		if msg.include?('PING') == true

			ws.send "PONG :tmi.twitch.tv"
			ws.pong
		elsif msg.include?(' PRIVMSG ')
			#puts msg
			msg = msg.downcase
			#puts "Received message: #{msg.strip}"

			metadata = msg.split(' ')[0]

			if metadata.include?('badges=broadcaster/1') || metadata.include?('badges=moderator/1')
				user_msg_arr = msg.split(' ')
				if user_msg_arr.to_s.include?('!lightsoff')
					puts "HueFighter turned the lights off."
					Huey::Bulb.all.update(on: false)
				elsif user_msg_arr.to_s.include?('!lightson')
					puts "HueFigher turned the lights on."
					Huey::Bulb.all.update(on: true)
				elsif user_msg_arr.to_s.include?('!alert')
					puts "HueFighter sent an alert."
=begin
					Huey::Bulb.all.alert!
					sleep 1
					Huey::Bulb.all.alert!
					sleep 1
					Huey::Bulb.all.alert!
					sleep 1
					Huey::Bulb.all.alert!
					sleep 1
					Huey::Bulb.all.alert!
					sleep 1
=end
				elsif user_msg_arr.to_s.include?('!adminreset')
					puts "HueFighter reset everything."
					Huey::Bulb.all.update(on: true, rgb: configatron.basecolor)

				elsif user_msg_arr.to_s.include?('!colorforce')

					user_msg_arr.shift
					user_msg_arr.shift
					user_msg_arr.shift
					user_msg_arr.shift
					$hex_col = user_msg_arr[-1]
					puts "HueFighter set the @group to: #{$hex_col}"
					#@group.update(rgb: $hex_col)
				elsif user_msg_arr.to_s.include?('!partymode')
					@i = 0
					@r = 0
					EM.tick_loop do
						partymode
						resetlights
					end
				end
			end
			if(metadata.include?('bits='))

				user_msg_arr = msg.split(' ')

				user_bit_amt = user_msg_arr[0].scan(/bits=(\d+)/).last.first

				#puts user_bit_amt

				user_msg_arr.shift
				user_msg_arr.shift
				user_msg_arr.shift
				user_msg_arr.shift

				user_msg_arr[0] = user_msg_arr[0].delete_prefix(':')

				#user_msg = user_msg_arr.join(' ')


				#puts user_msg

				user_msg_arr.each{ |word|
					$hex_col = ''
					#puts word
					if(configatron.colors.has_key?(word))
						#puts "name: #{configatron.colors[word]}"

						$hex_col = configatron.colors[word]

					elsif(/#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]\b/.match?(word))
						#puts "hex: #{word}"

						$hex_col = word

					end

					if($hex_col!='')
						cheer_col = ColorConverter.rgb($hex_col)

						interp_value = user_bit_amt.to_f / configatron.bitcap.to_f
						if(interp_value>1.0)
							interp_value=1.0
						end

						$red = $red + ((cheer_col[0] - $red).to_f * interp_value).to_i
						$green = $green + ((cheer_col[1] - $green).to_f * interp_value).to_i
						$blue = $blue + ((cheer_col[2] - $blue).to_f * interp_value).to_i

						$hex_out = ColorConverter.hex($red, $green, $blue)

						puts "#{user_bit_amt} #{$hex_out} \n"

						@group.update(rgb: $hex_out)
					end

				}


			end

		elsif msg.include?(' JOIN ') || msg.include?(' PART ')

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



