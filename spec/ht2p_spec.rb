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

  it '見た目は Hash として動作' do
    @header['a'] = 'A'
    @header['a'].should == 'A'

    @header['a'] = 'a'
    @header['a'] = 'A'
    @header['a'].should == 'A'
  end

  it 'class メソッドの load は HTTP ヘッダーを読み込む' do
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

  it 'format メソッドは HTTP ヘッダー文字列を返す' do
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

    @header['b'] = 'b'
    uri = URI.parse('http://example.com/')
    s =<<END
GET / HTTP/1.1
Host: example.com
a: A
b: b

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

    @header.add('b', 'B')
    uri = URI.parse('http://example.com/')
    s =<<END
GET / HTTP/1.1
Host: example.com
a: A
b: B
b: B

END
    @header.format(:get, uri).should == s.gsub("\n", "\r\n")

    @header['b'] = 'b'
    uri = URI.parse('http://example.com/')
    s =<<END
GET / HTTP/1.1
Host: example.com
a: A
b: b

END
    @header.format(:get, uri).should == s.gsub("\n", "\r\n")
  end
end
