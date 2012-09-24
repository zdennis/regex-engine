# encoding: utf-8

class MyRegex
  def initialize(pattern, sub=false)
    @patterns = []
    @sub = sub

    # strip out leading/trailing slashes
    @pattern = sub ? pattern : pattern[1..-2] 

    puts "Compiling: #{@pattern.inspect}" if ENV["DEBUG"]
    compile @pattern
  end

  def =~(str)
    if md=match(str)
      md.offset
    end
  end

  def match(str)
    _match(str)
  end

  def can_match_again?
    @patterns.detect{ |p| p.can_match_again? }
  end

  private

  def compile(pattern)
    pindex = 0

    while pattern.length > 0 && pindex < pattern.length
      char = pattern[pindex]
      prev_acceptor = @patterns.last

      if begin_subexpression?(char)
        subpattern= ""
        nested_count = 0
        loop do
          pindex += 1
          char = pattern[pindex]
          nested_count += 1 if begin_subexpression?(char)
          break if (end_subexpression?(char) && nested_count == 0) || pindex >= pattern.length
          nested_count -= 1 if end_subexpression?(char)
          subpattern << pattern[pindex]
        end
        @patterns << MyRegex.new(subpattern, true)
      elsif is_lazy?(prev_acceptor, char)
        @patterns[-1] = LazyQuantifier.new(prev_acceptor)
      elsif acceptor_klass=wrap_previous_acceptor_map[char]
        @patterns[-1] = acceptor_klass.new(prev_acceptor)
      elsif acceptor_klass=add_acceptor_map[char]
        @patterns << acceptor_klass.new(char)
      end

      next_index = pindex + 1          
      pattern = pattern[next_index..-1]
      pindex  = 0
    end
  end

  def add_acceptor_map
    @add_acceptor_map ||= Hash.new(Character).merge("." => Wildcard)
  end

  def begin_subexpression?(char)
    char == "("
  end

  def end_subexpression?(char)
    char == ")"
  end

  def is_lazy?(acceptor, char)
    acceptor.is_a?(MatchingGroup) && char == "?"    
  end

  def wrap_previous_acceptor_map
    @wrap_previous_acceptor_map ||= {
      "?" => ZeroOrOneGreedy, 
      "*" => ZeroOrMoreGreedy,
      "+" => OneOrMoreGreedy 
    }
  end

  def _match(str)
    offset = nil
    sindex = 0
    pindex = 0

    patterns_to_match = @patterns.dup
    captures = []

    stack = []

    loop do 
      exhausted = (stack.empty? && sindex >= str.length) || pindex >= @patterns.length
      break if exhausted

      str2match = str[sindex..-1]
      pattern = patterns_to_match[pindex]

      if md=pattern.match(str2match)
        stack << OpenStruct.new(:pindex => pindex, :sindex => sindex) if pattern.can_match_again?
        captures.concat md.captures
        offset = md.offset + sindex if offset.nil?
        sindex += md.offset + md.length
        pindex += 1
        puts "Matched: #{str.sub(/(.{#{sindex}})(.*)/, '\1ˍ\2')} against #{@pattern.sub(/(.{#{pindex}})(.*)/, '\1ˍ\2')}" if ENV["DEBUG"]
      elsif stack.any?
        puts " --> rolling back (captures.last.inspect)" if ENV["DEBUG"]
        last_match = stack.pop
        captures.pop
        pindex = last_match.pindex
        sindex = last_match.sindex
      else
        sindex += 1
        pindex = 0
        offset = nil
        puts "No match #{str.sub(/(.{#{sindex}})(.*)/, '\1ˍ\2')} against #{@pattern.sub(/(.{#{pindex}})(.*)/, '\1ˍ\2')}" if ENV["DEBUG"]
      end
    end

    if pindex >= @patterns.length
      if @sub
        captures = [str[offset..sindex - 1]].concat captures
      end
      MatchData.new(:offset => offset, :length => sindex - offset, :captures => captures)
    end
  end

  class MatchData
    attr_reader :offset, :length, :captures

    def initialize(options)
      @offset = options[:offset]
      @length = options[:length]
      @captures = options[:captures] || []
    end
  end

  class Matching
    attr_reader :max_length

    def self.matches_required(*args)
      args.any? ? @matches_required = args.first : @matches_required
    end

    def can_match_again?
      max_length >= matches_required
    end

    def matches_required
      self.class.matches_required
    end

    def initialize(pattern)
      @pattern = pattern
      @max_length = 0
    end

    def match(str, max_length)
      raise "Override in subclass"
    end

    def to_s
      "<#{self.class.name} pattern=#{@pattern.inspect}>"
    end
  end

  class Character < Matching
    self.matches_required 1

    def match(str)
      # if max_length is 0 then we'll never match because there's nothing
      # to match on. If max_length is greater than 1, than we'll never match
      # because we only ever match on a single character.
      if str && str[0] == @pattern[0]
        MatchData.new :offset => 0, :length => 1
      end
    end
  end

  class Wildcard < Matching
    self.matches_required 1

    def match(str)
      if str.length > 0
        MatchData.new :offset => 0, :length => 1
      end
    end
  end

  class MatchingGroup < Matching
    def initialize(*)
      super
      @max_length = -1
    end

    def match(str, max_length=@max_length)
      str2match = str[0..-1]
      matched_length = 0
      number_of_times_matched = 0

      if max_length == -1 || max_length > 0
        loop do
          md = @pattern.match(str2match)
          break if md.nil?

          number_of_times_matched += 1
          matched_length += md.length
          str2match = str2match[1..-1]

          break if matched_length == max_length
        end
      end

      met_minimum_match = matches_required <= number_of_times_matched
      if met_minimum_match
        @matched_at = 0
        @max_length = number_of_times_matched - 1
        MatchData.new :offset => 0, :length => number_of_times_matched
      else 
        @max_length = 0
        nil
      end
    end

    def to_s
      "<#{self.class.name} acceptor=#{@pattern.inspect}>"
    end
  end

  class ZeroOrMoreGreedy < MatchingGroup
    self.matches_required 0
  end

  class LazyQuantifier < MatchingGroup
    def initialize(*)
      super
      @max_length = @pattern.matches_required
    end

    def match(str)
      return nil if @max_length > str.length
      @pattern.match(str, @max_length).tap do
        @max_length += 1
      end
    end

    def matches_required
      @pattern.matches_required
    end
  end

  class ZeroOrOneGreedy < MatchingGroup
    self.matches_required 0

    def initialize(*)
      super
      @max_length = 1
    end
  end

  class OneOrMoreGreedy < MatchingGroup
    self.matches_required 1
  end
end