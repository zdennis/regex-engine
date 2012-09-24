require 'spec_helper'

describe "regex matching" do
  subject(:regex_engine) { MyRegex.new(pattern) }
  let(:pattern){ example.example_group.description }

  def self.pattern(*args, &blk)
    describe *args, &blk
  end

  def self.should_match(str, options)
    it "matches #{str.inspect}" do
      md = regex_engine.match(str)
      md.offset.should eq(options[:at])
      md.length.should eq(options[:length]) if options[:length]
      md.captures.should eq(options[:captures]) if options[:captures]
    end
  end

  def self.should_not_match(str)
    it "doesn't match #{str.inspect}" do
      md = regex_engine.match(str)
      md.should be_nil
    end
  end

  pattern "/a/" do
    should_match "a", :at => 0, :length => 1

    should_not_match ""
    should_not_match "b"
  end

  pattern "/abc/" do
    should_match "abc", :at => 0, :length => 3
    should_match "zabc", :at => 1, :length => 3

    should_not_match "bca"
    should_not_match "cba"
    should_not_match "ab."
  end

  pattern "/a.c/" do
    should_match "abc", :at => 0, :length => 3
    should_match "zabc", :at => 1, :length => 3
    should_match "zadcasdf", :at => 1, :length => 3

    should_not_match "cbc"
    should_not_match "zabd"
    should_not_match "zadbca"
  end

  describe "0 or more occurrences" do
    pattern "/a.*ca.*c/" do
      should_match "acabc", :at => 0, :length => 5
      should_match "abcac", :at => 0, :length => 5
      should_match "acac", :at => 0, :length => 4
      should_match "abcabc", :at => 0, :length => 6
      should_match "zyxabcabbbbbbcabc", :at => 3, :length => 14

      should_not_match "abcc"
      should_not_match "abcabd"
    end    

    pattern "/a.*c/" do
      should_match "ac", :at => 0, :length => 2
      should_match "abc", :at => 0, :length => 3
      should_match "abbc", :at => 0, :length => 4
      should_match "zabdddddc", :at => 1, :length => 8
      should_match "zadcasdf", :at => 1, :length => 3
      should_match "zacasdfacg", :at => 1, :length => 8

      should_not_match "abddddd"
    end

    describe "<.*>" do 
      should_match "<em>foo</em>", :at => 0, :length => 12
    end

    describe "lazy matches" do
      pattern "/<.*?>/" do
        should_match "<>", :at => 0, :length => 2
        should_match "<em>foo", :at => 0, :length => 4
        should_match "<em>foo</em>", :at => 0, :length => 4
      end    
    end

    pattern "/ab*c/" do
      should_match "abc", :at => 0, :length => 3
      should_match "abbbbbbbbbbbbc", :at => 0, :length => 14
      should_match "zacasdfacg", :at => 1, :length => 2
      should_match "abbc", :at => 0, :length => 4

      should_not_match "zabdddddc"
      should_not_match "zadcasdf"
      should_not_match "abddddd"
    end
  end

  describe "1 or more occurrences" do
    pattern "/a.+ca.+c/" do
      should_match "abcabc", :at => 0, :length => 6
      should_match "zyxabcabbbbbbcabc", :at => 3, :length => 14

      should_not_match "acabc"
      should_not_match "abcac"
      should_not_match "acac"
      should_not_match "abcc"
      should_not_match "abcabd"
    end    

    pattern "/a.+c/" do
      should_match "abc", :at => 0, :length => 3
      should_match "abbc", :at => 0, :length => 4
      should_match "zabdddddc", :at => 1, :length => 8
      should_match "zadcasdf", :at => 1, :length => 3
      should_match "zacasdfacg", :at => 1, :length => 8

      should_not_match "ac"
      should_not_match "abddddd"
    end

    pattern "/ab+c/" do
      should_match "abc", :at => 0, :length => 3
      should_match "abbbbbbbbbbbbc", :at => 0, :length => 14
      should_match "abbc", :at => 0, :length => 4

      should_not_match "ac"
      should_not_match "zacasdfacg"
      should_not_match "zabdddddc"
      should_not_match "zadcasdf"
      should_not_match "abddddd"
    end

    pattern "/<.+>/" do
      should_match "<em>foo", :at => 0, :length => 4
      should_match "<em>foo</em>", :at => 0, :length => 12
    end 

    describe "lazy matches" do
      pattern "/<.+?>/" do
        should_match "<e>", :at => 0, :length => 3
        should_match "<em>foo", :at => 0, :length => 4
        should_match "<em>foo</em>", :at => 0, :length => 4

        should_not_match "<>"
      end
    end
  end

  describe "0 or 1 occurrence" do
    pattern "/ab?c/" do
      should_match "ac", :at => 0, :length => 2
      should_match "abc", :at => 0, :length => 3

      should_not_match "abbc"
    end

    describe "greedy matches" do
      pattern "/ab?bb/" do
        should_match "abbb", :at => 0, :length => 4
      end
    end

    describe "lazy matches" do
      pattern "/ab??bb/" do
        should_match "abbb", :at => 0, :length => 3
      end
    end
  end

  describe "mixing modifiers" do
    pattern "/a+bc*d/" do
      should_match "abcd", :at => 0, :length => 4
      should_match "aaaabcd", :at => 0, :length => 7
      should_match "aaaabccccccccd", :at => 0, :length => 14
      should_match "aaaabd", :at => 0, :length => 6

      should_not_match "bcd"
      should_not_match "aaabbbbbcd"
    end

    pattern "/a*.c+d/" do
      should_match "abcd", :at => 0, :length => 4
      should_match "aaaabcd", :at => 0, :length => 7
      should_match "aaaabccccccccd", :at => 0, :length => 14
      should_match "bcd", :at => 0, :length => 3

      should_not_match "aaaabd"
      should_not_match "aaabbbbbcd"
    end
  end

  describe "sub-expressions" do
    pattern "/(abc)/" do
     should_match "abc", :at => 0, :length => 3, :captures => ["abc"]
      should_match "cabc", :at => 1, :length => 3, :captures => ["abc"]
      should_match "cabcabc", :at => 1, :length => 3, :captures => ["abc"]

      should_not_match "bbc"
    end

    pattern "/(abc)(abc)/" do
      should_match "abcabc", :at => 0, :length => 6, :captures => ["abc", "abc"]
    end

    describe "/(.*?b)a/" do
      should_match "aabab", :at => 0, :length => 4, :captures => ["aab"]
      should_match "abcdefaba", :at => 0, :length => 9, :captures => ["abcdefab"]
    end

    describe "/bo(b.)mb/" do
      should_match "yabobombastic", :at => 2, :length => 6, :captures => ["bo"]
      should_match "bobomb", :at => 0, :length => 6, :captures => ["bo"]
    end

    describe "/he(l+(o)) world/", current: true do
      should_match "hello world", :at => 0, :length => 11, :captures => ["llo", "o"]
      should_match "helllllo world", :at => 0, :length => 14, :captures => ["lllllo", "o"]
    end

  end

end