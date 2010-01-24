require 'uri'
require 'socket'
require 'openssl'
require 'timeout'
require 'forwardable'

class HT2P::Client
  include ::HT2P

  alias __timeout timeout
  attr_accessor :timeout

  attr_reader :uri, :request

  def initialize(uri, params={}, &block)
    @uri = URI.parse(uri)
    @timeout = params[:timeout] || 30

    ip = IPSocket.getaddress(@uri.host)
    ip = nil if /\A127\.|\A::1\z/ =~ ip

    socket = nil
    _timeout do
      socket = TCPSocket.open(ip, @uri.port)
    end

    begin
      if @uri.scheme == 'https'
        context = OpenSSL::SSL::SSLContext.new
        context.ca_file = params[:ca_file]
        context.ca_path = params[:ca_path] || OpenSSL::X509::DEFAULT_CERT_DIR
        context.timeout = params[:timeout]
        context.verify_depth = params[:verify_depth]
        context.verify_mode  = OpenSSL::SSL.const_get\
          "VERIFY_#{(params[:verify_mode] || 'PEER').to_s.upcase}"

        @socket = OpenSSL::SSL::SSLSocket.new(socket, context)
        _timeout do
          @socket.connect
        end
        @request = HT2P::Client::Request.new(self, params)
        block.call @request
      else
        @socket = socket
        @request = HT2P::Client::Request.new(self, params)
        block.call @request
      end
    ensure
      @socket.close
    end
  end

  def _timeout(&block)
    __timeout @timeout, TimeoutError, &block
  end
  private :_timeout

  def write(val)
    _timeout do
      @socket.write val
    end
  end

  def read(val=nil)
    _timeout do
      @socket.read(val)
    end
  end

  def gets
    _timeout do
      @socket.gets
    end
  end

  def flush
    _timeout do
      @socket.flush
    end
  end

  autoload :Request, 'ht2p/client/request'
  autoload :Response, 'ht2p/client/response'
end
