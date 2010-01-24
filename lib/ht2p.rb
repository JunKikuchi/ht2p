module HT2P
  autoload :Header, 'ht2p/header'
  autoload :Client, 'ht2p/client'

  class Error < StandardError; end
  class TimeoutError < Error; end
end
