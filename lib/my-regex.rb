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
      puts "pattern length: #{@pattern.length}"
    end

    def accept(str)
      pattern_index = 0
      str_index = 0
      backtracks = []      
      is_modifier = false

      printf "%12s | %12s | %12s | %12s |\n", "str_index", "current_str", "pidx", "current_ptn"
      loop do
        current_str = str[str_index]
        current_ptn = @pattern[pattern_index]
        prev_str    = str[str_index - 1] if str_index > 0
        prev_ptn    = @pattern[pattern_index-1] if pattern_index > 0
        printf "%12s | %12s | %12s | %12s | ", str_index, current_str, pattern_index, current_ptn
        debug = ""

        if current_str == current_ptn || current_ptn == "."
          debug = "0"
          str_index += 1
          pattern_index += 1
        elsif is_modifier && current_ptn == "*"
          if current_str == prev_str || prev_str == "."
            debug = "4.1"
            str_index += 1
          else
            debug = "4.2 - #{str_index}"
            backtracks << str_index
            is_modifier = false
            pattern_index += 1
          end
        elsif is_modifier
          debug = "1"
          is_modifier = false
          pattern_index += 1
        elsif !is_modifier && current_ptn == "*"
          debug = "2"
          str_index += 1
          is_modifier = true
        elsif str_index == 0
          debug = "3"
          str_index += 1
        elsif backtracks.any?
          debug = "5"          
          str_index = backtracks.pop
          pattern_index += 1
        else
          pattern_index = 0
          debug = "6"
          str_index += 1
        end

        puts debug

        if pattern_index >= @pattern.length
          return true
        elsif str_index == str.length
          return false
        end
      end
    end
  end

end