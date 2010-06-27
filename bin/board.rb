#!/usr/bin/env ruby

require "rubygems"
require "yaml"
require "eventmachine"
require "evented_redis"
require "thin"
require "web_board"


EventMachine::run do
  cfg = YAML.load_file("config/config.yml")
  red = EventedRedis.connect(cfg["redis"]["host"], cfg["redis"]["port"])
  web = WebBoard.connect(cfg["thin"]["socket"])

  red.psubscribe("b/*") do |type,_,chan,msg|
    next unless type == "pmessage"
    chan = chan[2, chan.size]
    $stderr.puts "New message: #{chan} -> #{msg}"
    web.message(chan, msg)
  end

  trap('HUP') do
    # reload
  end

  trap('TERM') do
    # stop
    red.close_connection_after_writing
    EventMachine.stop if EventMachine.reactor_running?
  end
end
