require 'uri'
require 'socket'
require 'openssl'
require 'forwardable'

class HT2P::Client
  extend Forwardable
  def_delegators :@socket, :write, :read, :gets, :flush

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

  autoload :Request, 'ht2p/client/request'
  autoload :Response, 'ht2p/client/response'
end
