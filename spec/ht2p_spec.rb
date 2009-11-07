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
