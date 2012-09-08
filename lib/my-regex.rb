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
    def is_any_char?(ch)
      ch == "."
    end

    def is_zero_or_more?(ch)
      ch == "*"
    end

    def is_one_or_more?(ch)
      ch == "+"
    end

    def initialize(pattern)
      pindex = 0
      @acceptors = []

      loop do
        current_ch = pattern[pindex]
        next_ch    = pattern[pindex+1]
        puts "START: #{pattern[pindex].inspect}  #{current_ch.inspect}" if ENV["DEBUG"]

        if is_zero_or_more?(current_ch)
          prev_acceptor = @acceptors.last
          @acceptors[-1] = ZeroOrMoreAcceptor.new(prev_acceptor)

          next_index = pindex + 1          
          pattern = pattern[next_index..-1]
          pindex  = 0
        elsif is_one_or_more?(current_ch)
          prev_acceptor = @acceptors.last
          @acceptors[-1] = OneOrMoreAcceptor.new(prev_acceptor)

          next_index = pindex + 1          
          pattern = pattern[next_index..-1]
          pindex  = 0
        elsif is_any_char?(current_ch)
          @acceptors << AnyCharacterAcceptor.new(current_ch)

          next_index = pindex + 1          
          pattern = pattern[next_index..-1]
          pindex  = 0
        else
          @acceptors << SimpleCharacterAcceptor.new(current_ch)

          next_index = pindex + 1          
          pattern = pattern[next_index..-1]
          pindex  = 0
        end
        break if pattern.length == 0 || (pindex == pattern.length)
      end
    end

    def accept?(str)
      str4match = str.dup
      acceptor_stack = @acceptors.dup
      accepted_stack = []
      sindex = 0

      loop do
        acceptor = acceptor_stack.first
        str4match = str[sindex..-1]
        puts "str4match: #{str4match.inspect} #{acceptor.inspect}" if ENV["DEBUG"]
        return false if str4match.nil? || acceptor.matched_length == 0

        if acceptor.accept?(str4match, acceptor.matched_length.to_i - 1)
          puts "  matched at #{sindex}, #{acceptor.matched_length}" if ENV["DEBUG"]
          sindex += acceptor.matched_length
          accepted_stack.push acceptor
          acceptor_stack = acceptor_stack[1..-1]
        elsif accepted_stack.empty?
          puts "  not matched (stack empty, move forward one character)" if ENV["DEBUG"]
          sindex += 1
        else
          puts "  not matched resetting" if ENV["DEBUG"] 
          acceptor_stack = [accepted_stack.pop].concat(acceptor_stack)
          accepted_stack = accepted_stack[1..-1] || []

          puts "  try again: #{sindex} to #{sindex - acceptor_stack.first.matched_length}" if ENV["DEBUG"]
          sindex -= acceptor_stack.first.matched_length
        end

        puts "sindex (#{sindex} == #{str.length})" if ENV["DEBUG"]

        return true if acceptor_stack.empty?
        return false if str4match.nil? || sindex > str.length
      end
    end
  end

  class Automaton
    attr_reader :matched_at, :matched_length

    def initialize(pattern)
      @pattern = pattern
    end

    def accept?(str, max_length)
      raise "Override in subclass"
    end
  end

  class SimpleCharacterAcceptor < Automaton
    def accept?(str, max_length=nil)
      return nil unless str

      if max_length == 0
        @matched_at = 0
        return false
      end

      sindex = 0
      pindex = 0
      loop do
        return if @matched_at == max_length

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

  class AnyCharacterAcceptor < Automaton
    def accept?(str, max_length=nil)
      if max_length == 0
        @matched_length = 0
      else
        (str.length > 0).tap do
          @matched_at = 0
          @matched_length = 1
        end
      end
    end
  end

  class AutomatonGroup < Automaton
    def self.matches_required(*args)
      args.any? ? @matches_required = args.first : @matches_required
    end

    def initialize(acceptor)
      @acceptor = acceptor
    end

    def matches_required
      self.class.matches_required
    end

    def accept?(str, max_length)
      @matched_at = 0 if @number_of_times_matched > 0
      matches_required <= @number_of_times_matched
    end
  end

  class ZeroOrMoreAcceptor < AutomatonGroup
    self.matches_required 0

    def accept?(str, max_length)
      @matched_length = 0
      @number_of_times_matched = 0      
      
      if max_length == -1 || (max_length && max_length > 0)
        while @acceptor.accept?(str, max_length)
          @number_of_times_matched += 1
          @matched_length += @acceptor.matched_length.to_i
          str = str[1..-1]

          break if max_length && @matched_length == max_length
        end
      end

      super
    end
  end

  class OneOrMoreAcceptor < AutomatonGroup
    self.matches_required 1

    def accept?(str, max_length)
      @matched_length = 0
      @number_of_times_matched = 0

      if max_length == -1 || (max_length && max_length > 0)
        while @acceptor.accept?(str, max_length)
          @number_of_times_matched += 1          
          @matched_length += @acceptor.matched_length.to_i
          str = str[1..-1]

          break if max_length && @matched_length == max_length
        end
      end

      super
    end
  end
end