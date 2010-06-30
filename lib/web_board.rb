class WebBoard
  AsyncResponse   = [-1, {}, []].freeze
  InvalidResponse = [500, {"Content-Type" => "text/html"}, ["Invalid request"]].freeze
  Header          = { "Content-Type" => "text/html; charset=utf8" }.freeze
  CacheSize       = 20

  def connect(socket, pid_file, log_file)
    web = self
    server = Thin::Server.new(socket) do
      map '/b' do
        run web
      end
    end
    if pid_file
      server.pid_file = pid_file
      server.log_file = log_file
      server.daemonize
    end
    server.start
  end

  def initialize
    @chans = {}
    @cache = []
  end

  def call(env)
    chan = env["PATH_INFO"].to_s
    chan = chan[1, chan.size]
    return InvalidResponse if chan == ""
    $stderr.puts "New web client: '#{chan}'"
    request  = Rack::Request.new(env)
    messages = in_cache(chan, request['cursor'])
    if messages.empty?
      (@chans[chan] ||= []) << env['async.callback']
      AsyncResponse
    else
      respond(messages)
    end
  end

  def message(chan, id, kind, msg)
    hash = {:id => id, :kind => kind, :msg => msg}
    @cache << hash.merge(:chan => chan)
    @cache.unshift if @cache.size > CacheSize
    (@chans.delete(chan) || []).each do |cb|
      cb.call respond([hash])
    end
  end

  def in_cache(chan, id)
    return [] if @cache.empty?
    index = @cache.rindex {|e| e[:id] == id } || -2
    @cache[index + 1, CacheSize].select {|e| e[:chan] == chan}
  end

  def respond(messages)
    body = Yajl::Encoder.encode(messages)
    [ 200, Header.dup, [body] ]
  end
end
