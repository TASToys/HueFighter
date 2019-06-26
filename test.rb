#!/usr/bin/env ruby2.6
require 'artii'
require 'lolize'

a = Artii::Base.new :font => 'slant'
colorize = Lolize::Colorizer.new
system('clear')
colorize.write(a.asciify('HueFighter'))
puts "\n Version 1.0.3"
