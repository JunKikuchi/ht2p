require 'uri'
require 'socket'
require 'openssl'

class HT2P::Client
  attr_reader :uri, :request

  def initialize(uri, params={}, &block)
    @uri = URI.parse(uri)

    ip = IPSocket.getaddress(@uri.host)
    ip = nil if /\A127\.|\A::1\z/ =~ ip

    TCPSocket.open(ip, @uri.port) do |socket|
      if @uri.scheme == 'https'
        begin
          @socket = OpenSSL::SSL::SSLSocket.new(socket)
          @socket.connect
          @request = HT2P::Client::Request.new(self, params)
          block.call @request
        ensure
          @socket.close
        end
      else
        @socket = socket
        @request = HT2P::Client::Request.new(self, params)
        block.call @request
      end
    end
  end

  def request_header(method, header)
    @socket.write header.format(method, @uri)
  end

  def response_header
    HT2P::Header.load @socket
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
