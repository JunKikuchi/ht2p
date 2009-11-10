class HT2P::Header < Hash
  def []=(key, val)
    if self.key? key
      if self[key].is_a? Array
        self[key] << val
      else
        super(key, [self[key], val])
      end
    else
      super(key, val)
    end
  end

  def to_s
    inject('') do |ret, (key, val)|
      if val.is_a? Array
        val.each do |v|
          ret << "#{key}: #{v}\r\n"
        end
      else
        ret << "#{key}: #{val}\r\n"
      end

      ret
    end
  end
end
