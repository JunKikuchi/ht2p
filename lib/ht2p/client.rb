require 'uri'
require 'resolv'
require 'socket'

class HT2P::Client
  attr_reader :uri

  def initialize(uri, params={}, &block)
    @uri = URI.parse(uri)

    TCPSocket.open(
      Resolv.getaddresses(@uri.host).collect do |val|
        if md = /[\d\.]+/.match(val)
          md[1]
        end
      end.shift,
      @uri.port
    ) do |s|
      @socket = s
      block.call Request.new(self, params)
      @socket = nil
    end
  end

  def request_header(method, header)
    @socket.write "#{method.to_s.upcase} #{@uri.path} HTTP/1.1\r\n"
    header.each do |key, val|
      if val.is_a? Array
        val.each do |v|
          @socket.write "#{key}: #{v}\r\n"
        end
      else
        @socket.write "#{key}: #{val}\r\n"
      end
    end
    @socket.write "\r\n"
  end

  def response_header
    code = nil
    header = {}

    while line = @socket.gets.chop!
      line.empty? && break

      if md = /(.+?):\s*(.*)/.match(line)
        key, val = md[1].downcase, md[2]

        if header.key? key
          if header[key].is_a? Array
            header[key] << val
          else
            header[key] = [header[key], val]
          end
        else
          header[key] = val
        end
      elsif md = %r!HTTP[\w\./]+\s+(\d+)!.match(line)
        code = md[1]
      end
    end

    [code.to_i, header]
  end

  def write(val)
    @socket.write val
  end

  def read(length)
    @socket.read length
  end

  def flush
    @socket.flush
  end

  autoload :Request, 'ht2p/client/request'
  autoload :Response, 'ht2p/client/response'
end
