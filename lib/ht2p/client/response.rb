class HT2P::Client::Response
  attr_reader :code, :header

  def initialize(client)
    @client, @code, @header = client, *client.response_header
  end

  def receive(&block)
    if block_given?
      block.call(self)
    else
      @client.read
    end
  end

  def read(length)
    @client.read(length)
  end
end
