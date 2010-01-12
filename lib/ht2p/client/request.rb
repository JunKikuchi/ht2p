class HT2P::Client::Request
  extend Forwardable
  def_delegators :@client, :write

  attr_accessor :uri, :method, :header

  alias :headers :header

  def initialize(client, params)
    @client = client
    @method = params[:method] || :get
    @header = HT2P::Header.new.merge!(params[:header] || {})
  end

  def send(body=nil, &block)
    @header['content-length'] = body.to_s.size if body
    @client.write @header.format(@method, @client.uri)
    @client.write body if body
    block.call self if block_given?
    @client.flush
    HT2P::Client::Response.new @client
  end

  METHODS = %w'get head post put delete options trace connect'
  METHODS.each do |val|
    define_method val, instance_method(:send)
  end
end
