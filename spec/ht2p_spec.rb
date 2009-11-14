require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe HT2P::Client do
  %w'get post put delete head'.each do |method|
    describe method do
      it "should perform a #{method}" do
        HT2P::Client.new('http://localhost:4567/echo/body') do |request|
          request.method = method.to_sym
          request.header['Accepts'] = 'text/html'
          if method != 'head'
            request.header['Content-Length'] = ("Hello World!\n" * 10000).size
            response = request.send do |io|
              10000.times do
                io.write "Hello World!\n"
              end
            end
          else
            request.header['Content-Length'] = 0
            response = request.send
          end

          response.code.should == 200
          response.header['content-type'] == 'text/html'
          body = ''
          response.receive do |io|
            while chunk = io.read(5)
              body << chunk
            end
          end

          body.should == ("Hello World!\n" * 10000) if method != 'head'
        end
      end
    end
  end
end

require 'stringio'

describe HT2P::Header do
  before do
    @header = HT2P::Header.new
  end

  it 'should store some keys and values like a Hash' do
    @header['a'] = 'A'
    @header['a'].should == 'A'
  end

  it 'should change the value to an Array if the key has been stored' do
    @header['a'] = 'A'
    @header['a'] = 'A'
    @header['a'].should == ['A', 'A']
  end

  it 'should perform `append` to append the value' do
    @header['a'] = 'A'
    @header.append('a', 'A')
    @header['a'].should == 'AA'

    @header['b'] = 'B'
    @header['b'] = 'B'
    @header.append('b', 'B')
    @header['b'].should == ['B', 'BB']
  end

  it 'should perform `load` to load HTTP header' do
    s =<<END
HTTP/1.1 100 continue
HTTP/1.1 200 ok
a:A
b:B
b: B
c:  C
 C
d: D
d: D
 D
END
    code, header = HT2P::Header.load(StringIO.new(s))
    code.should == 200
    header['a'].should == 'A'
    header['b'].should == ['B', 'B']
    header['c'].should == 'CC'
    header['d'].should == ['D', 'DD']
  end

  it 'should perform `format` to return header string' do
    uri = URI.parse('http://example.com/')
    s =<<END
GET / HTTP/1.1
Host: example.com

END
    @header.format(:get, uri).should == s.gsub("\n", "\r\n")

    @header['a'] = 'A'
    uri = URI.parse('http://example.com/')
    s =<<END
GET / HTTP/1.1
Host: example.com
a: A

END
    @header.format(:get, uri).should == s.gsub("\n", "\r\n")

    @header['b'] = 'B'
    uri = URI.parse('http://example.com/')
    s =<<END
GET / HTTP/1.1
Host: example.com
a: A
b: B

END
    @header.format(:get, uri).should == s.gsub("\n", "\r\n")

    @header['b'] = 'BB'
    uri = URI.parse('http://example.com/')
    s =<<END
GET / HTTP/1.1
Host: example.com
a: A
b: B
b: BB

END
    @header.format(:get, uri).should == s.gsub("\n", "\r\n")
  end
end
