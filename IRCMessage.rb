#!/usr/bin/env ruby
# frozen_string_literal: true

require 'oj'

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize

module Amethyst
  # Blah a comment
  class Prefix
    attr_reader :realname
    attr_reader :username
    attr_reader :hostname
    def initialize(data)
      @realname = @username = @hostname = ''
      if data[0] == ':'
        data2 = data[1..-1].split(/[!@]/)
        @realname = data2[0]
        @username = data2[1]
        @hostname = data2[2]
      end
    end
  end

  # Comment required by rubocop
  class Message
    attr_reader :raw
    attr_reader :tags
    attr_reader :parameters
    attr_reader :prefix
    attr_reader :command
    
    def initialize(data)
      @raw = data
      @tags = {}
      @parameters = []
      @prefix = nil
      data = data.split(' ')
      data2 = data.shift
      if data2[0] == '@'
        data2[1..-1].split(';').each {
            |r_tag| s_tag = r_tag.split('=', 2)
          @tags[s_tag[0]] = s_tag[1] }
        data2 = data.shift
      end
      if data2[0] == ':'
        @prefix = Prefix.new(data2)
        data2 = data.shift
      end
      @command = data2
      loop do
        if data[0].nil?
          break
        elsif data[0][0] == ':'
          @parameters.push(data.join(' ')[1..-1])
          break
        elsif data.length == 1
          @parameters.push(data[0])
          break
        else
          @parameters.push(data.shift)
        end
      end
    end

    def to_s
      Oj::dump self, indent: 2
    end

    def channel
      case @command
        when 'PRIVMSG', 'NOTICE', 'HOSTTARGET', 'ROOMSTATE', 'USERNOTICE', 'USERSTATE'
          @parameters[0]
        else
          nil
      end
    end

    def sender
      case @command
        when 'PRIVMSG', 'NOTICE'
          @prefix.realname
        else
          nil
      end
    end

    def message
      case @command
        when 'PRIVMSG', 'NOTICE'
          @parameters[1]
        else
          nil
      end
    end
  end

  # I'm only required to be here by Rubocop
  class TwitchMessage < Message
    def bits
      @tags['bits'].to_i
    end

    def moderator?
      (@tags['badges'].include? 'moderator') || broadcaster?
    end

    def broadcaster?
      @tags['badges'].include? 'broadcaster'
    end

    def subscriber?
      @tags['badges'].include? 'subscriber'
    end

    def turbo?
      @tags['badges'].include? 'turbo'
    end

    def prime?
      @tags['badges'].include? 'premium'
    end

    def partner?
      @tags['badges'].include? 'partner'
    end

    def vip?
      @tags['badges'].include? 'vip'
    end

    def admin?
      @tags['badges'].include? 'admin'
    end

    def globalmod?
      @tags['badges'].include? 'global_mod'
    end

    def staff?
      @tags['badges'].include? 'staff'
    end

    def color
      @tags['color']
    end
  end
end

# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
