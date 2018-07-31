# Colorful-Cheer

[![License](https://img.shields.io/badge/License-BSD%202--Clause-blue.svg?longCache=true&style=flat-square)](https://opensource.org/licenses/BSD-2-Clause)

Colorful-Cheer is a set of tools to control lights with different cheer events in a Twitch chat

---

## Requirements 
- Ruby 2.5.1
- EventMachine 1.2.7
- Websocket-Eventmachine-Client v1.2.0
- Huey v2.1.0
- Color-Converter 1.0.0
- tty-prompt 0.16.1
- rest-client 2.0.2 

## Set-up
1. clone or download this repository
2. `bundle install`
3. `cp example.config.rb config.rb`
4. run `bridge-connect.rb` to connect to your bridge
5. copy the provided uuid to `config.rb` for `configatron.user`
6. put the ip of your bridge into `config.rb` for `configatron.bridge`

## Running
1. run `./HueFighter.rb` if you need to change the lights used for the group that can be done inside the script. (for now.)


##TODO
- Party mode at 500 bits
- flash indicators for 100, 200, 300, 400 bits
- gui to show current color to stream
