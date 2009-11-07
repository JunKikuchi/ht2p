require 'rubygems'
require 'sinatra'

%w'get post put delete head'.each do |method|
  self.__send__ method.to_sym, '/echo/body' do
    request.body.read
  end
end
