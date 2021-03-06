class HT2P::Header < Hash
  def self.load(io)
    code = nil
    header = self.new

    key = nil
    while line = io.gets
      line.chop!
      line.empty? && break

      if md = %r!HTTP[\w\./]+\s+(\d+)!.match(line)
        code = md[1].to_i
      elsif md = /(.+?):\s*(.*)/.match(line)
        key, val = md[1].downcase, md[2]
        if header.key? key
          header.add key, val
        else
          header[key] = val
        end
      elsif md = /\s+(.*)/.match(line)
        header.append key, md[1]
      end
    end

    [code, header]
  end

  def add(key, val)
    if key? key
      if self[key].is_a? Array
        self[key] << val
      else
        self[key] = [self[key], val]
      end
    else
      self[key] = [val]
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

  def format(method, uri)
    "%s %s%s HTTP/1.1\r\n" % [
      method.to_s.upcase,
      uri.path,
      uri.query && "?#{uri.query}"
    ] << "Host: #{uri.host}\r\n" << to_s << "\r\n"
  end
end
