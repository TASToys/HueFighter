#!/usr/bin/env ruby
# frozen_string_literal: true

require 'eventmachine'
require 'faye/websocket'
require 'huey'
require 'color_converter'
require 'configatron'
require 'securerandom'
require 'paint'
require_relative 'IRCMessage'

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

@group = Huey::Group.new(configatron.lightarray)
@group.name = 'HueFighter'
@group.save
@group.on = true
@group.update(rgb: configatron.basecolor)
# some vars needed inside of party mode

@inti = 0
@reset = 0
@hex_col = nil
@hex_out = nil
@msg = nil

def partymode(ltotal)
  @inti = 0
  @reset = 0
  loop do
    break if @inti == ltotal + 1 # Let's leave our loop
    
    color = SecureRandom.hex(3)
    bulb = Huey::Bulb.find(rand(1..4))
    text = Paint["Set color to #{color} on light #{bulb.name}", color]
    puts text + "\n"
    bulb.update(rgb: "##{color}")
    @inti += 1
    sleep 0.25
  end
  puts 'PartyMode over resetting lights'
  loop do
    break if @reset == 1
    
    @group.update(rgb: configatron.basecolor, bri: 255)
    @reset += 1
  end
end

EM.run do
  ws = Faye::WebSocket::Client.new('ws://irc-ws.chat.twitch.tv')
  
  ws.on :open do |event|
    puts 'connected'
    ws.send('CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership')
    if configatron.talk == 'enabled'
      ws.send("PASS #{configatron.oauth}")
      ws.send("NICK #{configatron.nick}")
      ws.send("JOIN ##{configatron.channel}")
      ws.send("PRIVMSG ##{configatron.channel} :HueFighter online, let's do the thing.")
      
      @talking = true
    else
      ws.send("NICK justinfan#{rand(100_000..999_999)}")
      ws.send("JOIN ##{configatron.channel}")
      
      @talking = false
    end
  end
  
  ws.on :message do |event|
    msg1 = event.data
    msg = Amethyst::TwitchMessage.new(msg1)
    
    if msg.command == 'PING'
      ws.send('PONG :tmi.twitch.tv')
    
    elsif msg.command == ' PRIVMSG '
      msg = msg.downcase
      
      if msg.moderator? || msg.vip?
        
        if msg.message.split(' ')[0] == '!lightsoff'
          puts 'HueFighter turned the lights off.'
          Huey::Bulb.all.update(on: false)
        elsif if msg.message.split(' ')[0] == '!lightson'
                puts 'HueFighter turned the lights on.'
                Huey::Bulb.all.update(on: true)
              elsif msg.message.split(' ')[0] == '!alert'
                puts 'HueFighter sent an alert.'
                5.times { Huey::Bulb.all.alert!; sleep 1 }
              elsif msg.message.split(' ')[0] == '!adminreset'
                puts 'HueFighter reset everything.'
                Huey::Bulb.all.update(on: true, rgb: configatron.basecolor)
              elsif msg.message.split(' ')[0] == '!colorforce'
                @hex_col = msg.message.split(' ')[-1]
                puts "HueFighter set the group to: #{@hex_col}"
                @group.update(rgb: @hex_col)
              elsif msg.message.split(' ')[0] == '!partymode'
                partymode(250)
              end
        end
        if msg.message.split(' ')[0] == '!getcolor'
          if @talking == true
            if @hex_col.nil?
              ws.send("PRIVMSG ##{configatron.channel} :The lights are still set to default, cheer any amount and any hex value and I'll change it.")
            else
              ws.send("PRIVMSG ##{configatron.channel} :The lights are a nice shade of: #{@hex_col}")
            end
          end
        end
        if /\d+/.match(msg.bits.to_s)
          
          user_bit_amt = msg.bits
          
          msg.message
          msg.message.each { |word|
            @hex_col = ''
            
            if configatron.colors.key?(word)
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
        
        if /\d+/.match(msg.bits.to_s)
          bitamt = msg.bits
          if bitamt > 1000
            partymode(1000)
          elsif bitamt >= 500
            partymode(100)
          elsif bitamt >= 400
            partymode(40)
          elsif bitamt >= 300
            partymode(30)
          elsif bitamt >= 200
            partymode(20)
          elsif bitamt >= 100
            partymode(10)
          elsif bitamt >= 1
            partymode(5)
          end
        end
      elsif msg.command == ' JOIN ' || msg.command == ' PART '
      else
        # puts msg.strip
      end
    end
    ws.on :close do |event|
      puts "Disconnected with status code: #{event.code} #{event.reason}"
    
    end
    ws.on :error do |event|
      puts "Error: #{event.error}"
    
    end
    EventMachine.next_tick do
      puts 'tick!'
    end
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/LineLength, Style/BlockDelimiters
# rubocop:enable Style/IfUnlessModifier, Style/Next, Metrics/BlockNesting
