class MyRegex
  def initialize(pattern)
    # Only accept regexes in form of /../
    # so strip out the forward slashes at beginning
    # and end of the pattern
    @pattern = pattern[1..-2]

    @engine = Acceptor.new(@pattern)
  end

  def has_match?(str)
    @engine.accept(str)
  end

  class Acceptor
    def initialize(pattern)
      @pattern = pattern
      #@acceptors = [acceptor(@pattern)]
    end

    def accept(str)
      pattern_index = 0
      str_index = 0
      loop do
        if str[0] == @pattern[pattern_index]
          str_index += 1
          pattern_index += 1
          return true if pattern_index == @pattern.length
        else
          return false
        end
      end
      str.each_char
      # @acceptors.detect do |acceptor|
      #   acceptor.accept(str)
      # end    
    end
  end

end