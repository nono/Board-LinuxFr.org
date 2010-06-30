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
  red = EventedRedis.connect(cfg["redis"]["host"], cfg["redis"]["port"])
  web = WebBoard.connect(cfg["thin"]["socket"])

  red.psubscribe("b/*") do |type,_,chan,msg|
    next unless type == "pmessage"
    _,chan,id,kind = chan.split('/')
    $stderr.puts "New message: '#{chan}' (#{id} / #{kind}) -> #{msg}"
    web.message(chan, id, kind, msg)
  end

  # Don't trap signals, thin already do that
end
