class HT2P::Header < Hash
  def self.parse(io)
    code = nil
    header = self.new

    key = nil
    while line = io.gets
      line.chop!
      line.empty? && break

      if md = %r!HTTP[\w\./]+\s+(\d+)!.match(line)
        code = md[1]
      elsif md = /(.+?):\s*(.*)/.match(line)
        key, val = md[1].downcase, md[2]
        header[key] = val
      elsif md = /\s+(.*)/.match(line)
        header.append(key, md[1])
      end
    end

    [code.to_i, header]
  end

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

  def append(key, val)
    if self[key].is_a? Array
      self[key].last << val
    else
      self[key] << val
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
