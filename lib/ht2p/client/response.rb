class HT2P::Client::Response
  attr_reader :code, :header

  def initialize(client)
    @client, @code, @header = client, *client.response_header
  end

  def receive(&block)
    block.call(self) if block_given?
  end

  def read(length)
    @client.read(length)
  end
end
