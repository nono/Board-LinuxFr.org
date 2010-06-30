#!/usr/bin/env ruby

require "rubygems"
require "yaml"
require "eventmachine"
require "evented_redis"
require "thin"
require "yajl"
require "web_board"


EventMachine::run do
  cfg = YAML.load_file("config/config.yml")
  web = WebBoard.new
  web.connect(cfg["thin"]["socket"], cfg["daemonize"]["pid_file"], cfg["daemonize"]["log_file"])
  red = EventedRedis.connect(cfg["redis"]["host"], cfg["redis"]["port"])

  red.psubscribe("b/*") do |type,_,chan,msg|
    next unless type == "pmessage"
    _,chan,id,kind = chan.split('/')
    web.message(chan, id, kind, msg)
  end

  # Don't trap signals, thin already do that
end
