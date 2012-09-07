class MyRegex
  def initialize(pattern)
    # Only accept regexes in form of /../
    # so strip out the forward slashes at beginning
    # and end of the pattern
    @pattern = pattern[1..-2]

    @engine = Acceptor.new(@pattern)
  end

  def has_match?(str)
    @engine.accept?(str)
  end

  class Acceptor
    def is_modifier?(ch)
      ch == "."
    end

    def initialize(pattern)
      pindex = 0
      @acceptors = []
      current_acceptor_type = SimpleCharacterAcceptor

      current_pattern = ""

      # a.c
      loop do
        puts "START: #{pattern[pindex].inspect}  #{current_pattern.inspect}"
        current_ch = pattern[pindex]
        next_ch    = pattern[pindex+1]

        if is_modifier?(current_ch)
          @acceptors << current_acceptor_type.new(current_pattern)

          next_index = pindex + 1          
          pattern = pattern[next_index..-1]
          current_pattern = ""
          pindex  = 0

          @acceptors << AnyCharacterAcceptor.new(current_ch)
        else
          current_pattern << current_ch
          pindex += 1          
        end
        break if pattern.length == 0 || (pindex == pattern.length)
      end

      @acceptors << current_acceptor_type.new(current_pattern)

      puts @acceptors.inspect
    end

    def accept?(str)
      cindex = 0
      sindex = 0
      loop do
        str2match = str[cindex..-1]

        matched = @acceptors.all? do |a| 
          str4match = str2match[sindex..-1]
          a.accept?(str4match).tap do |value|
            sindex += a.matched_length if value
          end
        end
        return true if matched

        cindex += 1        
        return false if cindex == str.length
      end
    end

  end

  class SimpleCharacterAcceptor
    attr_reader :matched_at, :matched_length

    def initialize(pattern)
      @pattern = pattern
    end

    def accept?(str)
      return nil unless str
      
      sindex = 0
      pindex = 0
      loop do
        string_ch  = str[sindex]
        pattern_ch = @pattern[pindex]

        if string_ch == pattern_ch
          @matched_at = sindex      
          @matched_length = sindex + 1
          sindex += 1
          pindex += 1
        else
          return false          
        end

        if pindex >= @pattern.length
          return true
        elsif sindex == str.length 
          return false
        end
      end
    end
  end

  class AnyCharacterAcceptor
    attr_reader :matched_at, :matched_length

    def initialize(pattern)
      @pattern = pattern
    end

    def accept?(str)
      (str.length > 0).tap do
        @matched_at = 0
        @matched_length = 1
      end
    end
  end

end