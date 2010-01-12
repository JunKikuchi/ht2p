class HT2P::Client::Response
  attr_reader :code, :header

  alias :headers :header

  HAS_BODY = [:get, :post, :put, :delete, :trace]

  def initialize(client)
    @client, @code, @header = client, *HT2P::Header.load(client)

    @body = if HAS_BODY.include? @client.request.method.to_s.downcase.to_sym
      if @header['transfer-encoding'].to_s.downcase == 'chunked'
        Chunked.new @client
      else
        Transfer.new @client, @header['content-length'].to_i
      end
    else
      Empty.new
    end
  end

  def receive(&block)
    if block_given?
      block.call self
    else
      read
    end
  end

  def read(length=nil)
    @body.read length
  end

  class Transfer
    def initialize(client, size)
      @client, @size = client, size
    end

    def read(length=nil)
      if @size.nil?
        @client.read length
      elsif @size > 0
        length ||= @size
        length = @size if @size < length
        @size -= length

        @client.read length
      else
        nil
      end
    end
  end

  class Chunked < Transfer
    def initialize(client)
      super client, nil
      parse_size
    end

    def read(length=nil)
      parse_size if @size <= 0
      super length
    end

    def parse_size
      @size = @client.gets.chop!.hex
    end
    private :parse_size
  end

  class Empty
    def read(length=nil)
      nil
    end
  end
end
