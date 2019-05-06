#!/usr/bin/env ruby2.6
# frozen_string_literal: true

require 'eventmachine'
require 'websocket-eventmachine-client'
require 'huey'
require 'color_converter'
require 'configatron'
require 'securerandom'
require 'paint'


# Some rubocop settings to ingore things.
# rubocop:disable Metrics/BlockLength, Metrics/LineLength, Style/BlockDelimiters
# rubocop:disable Style/IfUnlessModifier, Style/Next, Metrics/BlockNesting

# Require our config files.

require_relative './config/config.rb'
require_relative './config/colors.rb'

class HueFighter
  def initialize()
    # handy dandy globals
    @i = 0
    @r = 0
    @hex_col = nil
    @hex_out = nil
    @msg = nil
    @red = 127
    @green = 127
    @blue = 127
  end
  
  def partymode
    loop do
      break if @i == 250 # Let's leave our loop

      color = SecureRandom.hex(3)
      # puts "Set color to ##{color} on light"
      bulb = Huey::Bulb.find([3,9].sample)
      text = Paint["Set color to ##{color} on light #{bulb.name}", color]

      puts text + "\n"

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
end

#set up the Huey group

@group = Huey::Group.new(Huey::Bulb.find(1), Huey::Bulb.find(2))
@group.name = 'HueFighter'
@group.on = true
@group.save
@group.update(rgb: configatron.basecolor)
# rubocop:enable Metrics/BlockLength, Metrics/LineLength, Style/BlockDelimiters
# rubocop:enable Style/IfUnlessModifier, Style/Next, Metrics/BlockNesting