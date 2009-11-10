class HT2P::Client::Request
  METHODS = %w'get head post put delete options trace connect'

  attr_accessor :uri, :method, :header

  def initialize(client, params)
    @client = client
    @method = params[:method] || :get
    @header = params[:header] || {}
  end

  def send(body=nil, &block)
    @client.request_header(@method, @header)
    @client.write(body)  if body
    block.call(self) if block_given?
    @client.flush
    HT2P::Client::Response.new(@client)
  end

  METHODS.each do |val|
    define_method(val, instance_method(:send))
  end

  def write(val)
    @client.write(val)
  end
end
