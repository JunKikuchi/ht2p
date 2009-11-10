require 'uri'
require 'socket'
require 'openssl'

class HT2P::Client
  attr_reader :uri

  def initialize(uri, params={}, &block)
    @uri = URI.parse(uri)

    ip = IPSocket.getaddress(@uri.host)
    ip = nil if /\A127\.|\A::1\z/ =~ ip

    TCPSocket.open(ip, @uri.port) do |socket|
      if @uri.scheme == 'https'
        begin
          @socket = OpenSSL::SSL::SSLSocket.new(socket)
          @socket.connect
          block.call HT2P::Client::Request.new(self, params)
        ensure
          @socket.close
        end
      else
        @socket = socket
        block.call HT2P::Client::Request.new(self, params)
      end
    end
  end

  def request_header(method, header)
    @socket.write "%s %s%s HTTP/1.1\r\n" % [
      method.to_s.upcase,
      @uri.path,
      @uri.query && "?#{@uri.query}"
    ]
    @socket.write "Host: #{@uri.host}\r\n"
    @socket.write header.to_s
    @socket.write "\r\n"
  end

  def response_header
    code = nil
    header = HT2P::Header.new

    key = nil
    while line = @socket.gets.chop!
      line.empty? && break

      if md = %r!HTTP[\w\./]+\s+(\d+)!.match(line)
        code = md[1]
      elsif md = /(.+?):\s*(.*)/.match(line)
        key, val = md[1].downcase, md[2]
        header[key] = val
      elsif md = /\s+(.*)/.match(line)
        header[key] = md[1]
      end
    end

    [code.to_i, header]
  end

  def write(val)
    @socket.write val.to_s
  end

  def read(length=nil)
    @socket.read length
  end

  def gets
    @socket.gets
  end

  def flush
    @socket.flush
  end

  autoload :Request, 'ht2p/client/request'
  autoload :Response, 'ht2p/client/response'
end
