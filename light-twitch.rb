#!/usr/bin/env ruby
require 'eventmachine'
require 'websocket-eventmachine-client'
require 'huey'


Huey.configure do |config|
  config.hue_ip = '192.168.1.244'
  config.uuid = "NqysWo8Fmlm4WE8M6Sxm-9UznfDoSnmFJOmg7q2g"
end


#bulb = Huey::Bulb.find('Desk')

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
				lightmsg = msg.split(';').at(1)
        puts lightmsg
        lightmsg1 = lightmsg.split('=').at(-1)
				puts lightmsg1
				Huey::Bulb.all.update(rgb: lightmsg1)
        #bulb.update(rgb: lightmsg1)
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

	ws.onping do |message|
		puts "Ping received: #{message}"
    ws.pong "PONG :tmi.twitch.tv"
  end

  ws.onpong do |message|
    puts "Pong sent: #{message}"
  end



	EventMachine.next_tick do
		puts "tick!"
	end
end

