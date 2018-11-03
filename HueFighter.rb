#!/usr/bin/env ruby2.5
# frozen_string_literal: true

require 'eventmachine'
require 'websocket-eventmachine-client'
require 'huey'
require 'color_converter'
require 'configatron'
require 'securerandom'

# Some rubocop settings to ingore things.
# rubocop:disable Metrics/BlockLength, Metrics/LineLength, Style/BlockDelimiters
# rubocop:disable Style/IfUnlessModifier, Style/Next, Metrics/BlockNesting
# Require our config files.

require_relative './config/config.rb'
require_relative './config/colors.rb'

# Set default values for lights.

@red = 127
@green = 127
@blue = 127

# configure huey, group, and turn on group.
Huey.configure do |config|
  config.hue_ip = configatron.bridge
  config.uuid = configatron.user
end

@group = Huey::Group.new(Huey::Bulb.find(1), Huey::Bulb.find(2))
@group.name = 'HueFighter'
@group.save
@group.on = true
@group.update(rgb: configatron.basecolor)

# some vars needed inside of party mode

@i = 0
@r = 0
@hex_col = nil
@hex_out = nil
@msg = nil

def partymode
  loop do
    break if @i == 240 # Let's leave our loop

    color = SecureRandom.hex(3)
    puts "Set color to ##{color} on light"
    bulb = Huey::Bulb.find(rand(1..4))
    bulb.update(rgb: "##{color}")

    @i += 1
    sleep 0.25
  end
end

def resetlights
  loop do
    break if @r == 1

    puts "Party mode over reseting color to #{@hex_col}"
    if @hex_col.nil?
      @group.update(rgb: configatron.basecolor)
    else
      @group.update(rgb: @hex_col)
    end
    @r += 1
  end
end

EM.run do
  ws = WebSocket::EventMachine::Client.connect(host: 'irc-ws.chat.twitch.tv', port: 80, ssl: false)

  ws.onopen do
    puts 'connected'
    ws.send 'CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership'
    if configatron.talk == 'enabled'
      ws.send "PASS #{configatron.oauth}"
      ws.send "NICK #{configatron.nick}"
      ws.send "JOIN ##{configatron.channel}"
      ws.send "PRIVMSG ##{configatron.channel} :HueFighter online, let's do the thing."
      @talking = true
    else
      ws.send "NICK justinfan#{rand(100_000..999_999)}"
      ws.send "JOIN ##{configatron.channel}"
      @talking = false
    end
  end

  ws.onmessage do |msg|
    if msg.include?('PING') == true
      ws.send 'PONG :tmi.twitch.tv'
      ws.pong
    elsif msg.include?(' PRIVMSG ')
      msg = msg.downcase
      metadata = msg.split(' ')[0]
      if metadata.include?('badges=broadcaster/1') || metadata.include?('badges=moderator/1')
        user_msg_arr = msg.split(' ')
        if user_msg_arr.to_s.include?('!lightsoff')
          puts 'HueFighter turned the lights off.'
          Huey::Bulb.all.update(on: false)
        elsif user_msg_arr.to_s.include?('!lightson')
          puts 'HueFigher turned the lights on.'
          Huey::Bulb.all.update(on: true)
        elsif user_msg_arr.to_s.include?('!alert')
          puts 'HueFighter sent an alert.'
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
        elsif user_msg_arr.to_s.include?('!adminreset')
          puts 'HueFighter reset everything.'
          Huey::Bulb.all.update(on: true, rgb: configatron.basecolor)
        elsif user_msg_arr.to_s.include?('!colorforce')
          user_msg_arr.shift
          user_msg_arr.shift
          user_msg_arr.shift
          user_msg_arr.shift
          @hex_col = user_msg_arr[-1]
          puts "HueFighter set the group to: #{@hex_col}"
          @group.update(rgb: @hex_col)
        elsif user_msg_arr.to_s.include?('!partymode')
          @i = 0
          @r = 0
          EM.tick_loop do
            partymode
            resetlights
          end
        end
      end
      if msg.split(' ')[-1].to_s.include?('!getcolor')
        if @talking == true
          if @hex_col.nil?
            ws.send "PRIVMSG ##{configatron.channel} :The lights are still set to default, cheer any amount and any hex value and I'll change it."
          else
            ws.send "PRIVMSG ##{configatron.channel} :The lights are a nice shade of: #{@hex_col}"
          end
        end
      end
      if metadata.include?('bits=')
        user_msg_arr = msg.split(' ')
        user_bit_amt = user_msg_arr[0].scan(/bits=(\d+)/).last.first
        # puts user_bit_amt
        user_msg_arr.shift
        user_msg_arr.shift
        user_msg_arr.shift
        user_msg_arr.shift
        user_msg_arr[0] = user_msg_arr[0].delete_prefix(':')
        # user_msg = user_msg_arr.join(' ')
        # puts user_msg
        user_msg_arr.each { |word|
          @hex_col = ''
          # puts word
          if configatron.colors.key?(word)
            # puts "name: #{configatron.colors[word]}"
            @hex_col = configatron.colors[word]
          elsif /#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]\b/.match?(word)
            # puts "hex: #{word}"
            @hex_col = word
          end
          if @hex_col != ''
            cheer_col = ColorConverter.rgb(@hex_col)
            interp_value = user_bit_amt.to_f / configatron.bitcap.to_f
            if interp_value > 1.0
              interp_value = 1.0
            end
            @red += ((cheer_col[0] - @red).to_f * interp_value).to_i
            @green += ((cheer_col[1] - @green).to_f * interp_value).to_i
            @blue += ((cheer_col[2] - @blue).to_f * interp_value).to_i
            @hex_out = ColorConverter.hex(@red, @green, @blue)
            puts "#{user_bit_amt} #{@hex_out} \n"
            @group.update(rgb: @hex_out)
          end
        }
      end
    elsif msg.include?(' JOIN ') || msg.include?(' PART ')
    else
      puts msg.strip
    end
  end
  ws.onclose do |code, reason|
    puts "Disconnected with status code: #{code} #{reason}"
  end
  ws.onerror do |error|
    puts "Error: #{error}"
  end
  EventMachine.next_tick do
    puts 'tick!'
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/LineLength, Style/BlockDelimiters
# rubocop:enable Style/IfUnlessModifier, Style/Next, Metrics/BlockNesting
