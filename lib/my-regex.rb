class MyRegex
  def initialize(pattern)
    @acceptors = []

    # strip out leading/trailing slashes
    @pattern = pattern[1..-2]

    compile @pattern
  end

  def =~(str)
    if md=match(str)
      md.offset
    end
  end

  private

  def compile(pattern)
    pindex = 0

    while pattern.length > 0 && pindex < pattern.length
      char = pattern[pindex]

      if acceptor_klass=wrap_previous_acceptor_map[char]
        prev_acceptor = @acceptors.last
        @acceptors[-1] = acceptor_klass.new(prev_acceptor)
      elsif acceptor_klass=add_acceptor_map[char]
        @acceptors << acceptor_klass.new(char)
      end

      next_index = pindex + 1          
      pattern = pattern[next_index..-1]
      pindex  = 0
    end
  end

  def add_acceptor_map
    @add_acceptor_map ||= Hash.new(SingleCharacterAcceptor).merge("." => AnyCharacterAcceptor)
  end

  def wrap_previous_acceptor_map
    @wrap_previous_acceptor_map ||= {
      "?" => ZeroOrOneAcceptor, 
      "*" => ZeroOrMoreAcceptor,
      "+" => OneOrMoreAcceptor 
    }
  end

  def match(str)
    str4match = str.dup
    acceptor_stack = @acceptors.dup
    accepted_stack = []
    sindex = 0
    offset = 0

    tried_states = []

    loop do
      acceptor = acceptor_stack.first
      str4match = str[sindex..-1]
      puts "str4match: #{str4match.inspect} #{acceptor.inspect}" if ENV["DEBUG"]

      possible_match_state = [sindex, acceptor, (acceptor && acceptor.retry_length)]

      if accepted_stack.length == 0
        offset = sindex
      end

      if str4match.nil? || tried_states.include?(possible_match_state)
        return false 
      end
      tried_states << possible_match_state

      if acceptor.match(str4match, acceptor.retry_length)
        puts "  matched at #{sindex}, #{acceptor.matched_length}" if ENV["DEBUG"]
        tried_states << possible_match_state
        sindex += acceptor.matched_length
        accepted_stack.push acceptor
        acceptor_stack = acceptor_stack[1..-1]
      elsif accepted_stack.empty?
        puts "  not matched (stack empty, move forward one character)" if ENV["DEBUG"]
        sindex += 1
      else
        puts "  not matched resetting" if ENV["DEBUG"] 
        acceptor_stack = [accepted_stack.pop].concat(acceptor_stack)
        accepted_stack = accepted_stack #[0..-2] || []

        puts "  try again: #{sindex} to #{sindex - acceptor_stack.first.matched_length}" if ENV["DEBUG"]
        sindex -= acceptor_stack.first.matched_length
      end

      puts "sindex (#{sindex} of #{str.length})" if ENV["DEBUG"]

      if acceptor_stack.empty?
        return MatchData.new(offset)
      elsif str4match.nil? || sindex > str.length
        return nil
      end
    end
  end

  class MatchData
    attr_reader :offset

    def initialize(offset)
      @offset = offset
    end
  end

  class Automaton
    attr_reader :matched_at, :matched_length

    def self.matches_required(*args)
      args.any? ? @matches_required = args.first : @matches_required
    end

    def matches_required
      self.class.matches_required
    end

    def initialize(pattern)
      @pattern = pattern
    end

    def match(str, max_length)
      raise "Override in subclass"
    end

    def retry_length
      matched_length.to_i - 1      
    end

    def to_s
      "<#{self.class.name} pattern=#{@pattern.inspect}>"
    end
  end

  class SingleCharacterAcceptor < Automaton
    self.matches_required 1

    def match(str, max_length=nil)
      # if max_length is 0 then we'll never match because there's nothing
      # to match on. If max_length is greater than 1, than we'll never match
      # because we only ever match on a single character.
      if max_length == 0 || max_length > 1
        @matched_at = 0
        @matched_length = nil
        false
      elsif str[0] == @pattern[0]
        @matched_at = 0
        @matched_length = 1
        true
      else
        @matched_at = 0
        @matched_length = nil
        false        
      end
    end
  end

  class AnyCharacterAcceptor < Automaton
    self.matches_required 1

    def match(str, max_length=nil)
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
    def initialize(acceptor)
      @acceptor = acceptor
    end

    def match(str, max_length)
      @matched_length = 0
      @number_of_times_matched = 0      

      puts "  --> #{self.class.name}  #{str.inspect} #{max_length}" if ENV["DEBUG"]
      
      if max_length == -1 || (max_length && max_length > 0)
        while @acceptor.match(str, max_length)
          @number_of_times_matched += 1
          @matched_length += @acceptor.matched_length.to_i
          str = str[1..-1]

          break if max_length && @matched_length == max_length
        end
      end

      @matched_at = 0 if @number_of_times_matched > 0
      matches_required <= @number_of_times_matched
    end

    def to_s
      "<#{self.class.name} acceptor=#{@acceptor.inspect}>"
    end
  end

  class ZeroOrMoreAcceptor < AutomatonGroup
    self.matches_required 0
  end

  class ZeroOrOneAcceptor < AutomatonGroup
    self.matches_required 0

    def initialize(*)
      super
      @retry_length = @acceptor.matches_required
    end

    def match(str, max_length)
      @matched_length = 0
      @number_of_times_matched = 0
      @retry_length += 1

      puts "  --| accept zero or one: #{str.inspect} #{max_length}" if ENV["DEBUG"]

      if max_length == -1 || (max_length && max_length > 0)
        if @acceptor.match(str, max_length)
          @number_of_times_matched += 1
          @matched_length += @acceptor.matched_length.to_i
        end
      end

      @matched_at = 0 if @number_of_times_matched > 0
      matches_required <= @number_of_times_matched
    end

    def retry_length
      @retry_length
    end
  end

  class OneOrMoreAcceptor < AutomatonGroup
    self.matches_required 1
  end
end