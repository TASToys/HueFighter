#!/usr/bin/env ruby2.6
# frozen_string_literal: true

require 'eventmachine'
require 'websocket-eventmachine-client'
require 'configatron'
require_relative 'config/config.rb'

class Twitchy
  def initalize(ws)
    @metadata = nil
    @msg = nil
    @ws = ws
  end
end