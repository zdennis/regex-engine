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
    # Types = {
    #   "."       => Any,
    #   "default" => Acceptor
    # }

    def initialize(pattern)
      @pattern = pattern

      # @acceptors = []
      # str = ""
      # type = Types["default"]
      # @pattern.each_char do |ch|
      #   if t=Types[ch]
      #     @acceptors << type.new(str)
      #     str = ""
      #     type = t
      #   else
      #     str << ch
      #   end
      # end
    end

    def accept(str)
      # @acceptors.all? do |acceptor|
      #   acceptor.accept(str)
      # end
      pattern_index = 0
      str_index = 0
      loop do
        current_str = str[str_index]
        current_ptn = @pattern[pattern_index]
        #puts "current #{current_str} at #{str_index} pattern #{current_ptn} at #{pattern_index}"
        if current_str == current_ptn || current_ptn == "."
          str_index += 1
          pattern_index += 1
          return true if pattern_index == @pattern.length
        elsif str_index == 0
          str_index += 1
          return false if str_index == str.length
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