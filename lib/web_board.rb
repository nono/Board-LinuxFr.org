class WebBoard
  AsyncResponse = [-1, {}, []].freeze
  InvalidResponse = [500, {"Content-Type" => "text/html"}, ["Invalid request"]].freeze
  Header = { "Content-Type" => "text/html; charset=utf8" }.freeze

  def self.connect(socket)
    web = self.new
    Thin::Server.start(socket) do
      use Rack::CommonLogger
      map '/b' do
        run web
      end
    end
    web
  end

  def initialize
    @chans = {}
  end

  def call(env)
    chan = env["PATH_INFO"].to_s
    chan = chan[1, chan.size]
    return InvalidResponse if chan == ""
    $stderr.puts "New web client: '#{chan}'"
    (@chans[chan] ||= []) << env['async.callback']
    AsyncResponse
  end

  def message(chan, msg)
    callbacks = @chans.delete(chan) || []
    callbacks.each do |cb|
      cb.call [ 200, Header.dup, [msg] ]
    end
  end
end
