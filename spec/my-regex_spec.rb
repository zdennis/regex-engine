require 'spec_helper'

describe "regex matching" do
  subject(:regex_engine) { MyRegex.new(pattern) }
  let(:pattern){ example.example_group.description }

  def self.should_match(str, options)
    it "matches #{str.inspect}" do
      offset = regex_engine =~ str
      offset.should eq(options[:at])
    end
  end

  def self.should_not_match(str)
    it "doesn't match #{str.inspect}" do
      offset = regex_engine =~ str
      offset.should be_nil
    end
  end

  describe "/a/" do
    should_match "a", :at => 0

    should_not_match ""
    should_not_match "b"
  end

  describe "/abc/" do
    should_match "abc", :at => 0
    should_match "zabc", :at => 1

    should_not_match "bca"
    should_not_match "cba"
    should_not_match "ab."
  end

  describe "/a.c/" do
    should_match "abc", :at => 0
    should_match "zabc", :at => 1
    should_match "zadcasdf", :at => 1

    should_not_match "cbc"
    should_not_match "zabd"
    should_not_match "zadbca"
  end

  describe "0 or more occurrences" do
    describe "/a.*ca.*c/" do
      should_match "acabc", :at => 0
      should_match "abcac", :at => 0
      should_match "acac", :at => 0
      should_match "abcabc", :at => 0
      should_match "zyxabcabbbbbbcabc", :at => 3
      
      should_not_match "abcc"
      should_not_match "abcabd"
    end    

    describe "/a.*c/" do
      should_match "ac", :at => 0
      should_match "abc", :at => 0
      should_match "abbc", :at => 0
      should_match "zabdddddc", :at => 1
      should_match "zadcasdf", :at => 1
      should_match "zacasdfacg", :at => 1

      should_not_match "abddddd"
    end

    describe "/<.*?>/" do
      should_match "<>", :at => 0
      should_match "<em>foo", :at => 0
      should_match "<em>foo</em>", :at => 0
    end    

    describe "/ab*c/" do
      should_match "abc", :at => 0
      should_match "abbbbbbbbbbbbc", :at => 0
      should_match "zacasdfacg", :at => 1
      should_match "abbc", :at => 0

      should_not_match "zabdddddc"
      should_not_match "zadcasdf"
      should_not_match "abddddd"
    end
  end

  describe "1 or more occurrences" do
    describe "/a.+ca.+c/" do
      should_match "abcabc", :at => 0
      should_match "zyxabcabbbbbbcabc", :at => 3

      should_not_match "acabc"
      should_not_match "abcac"
      should_not_match "acac"
      should_not_match "abcc"
      should_not_match "abcabd"
    end    

    describe "/a.+c/" do
      should_match "abc", :at => 0
      should_match "abbc", :at => 0
      should_match "zabdddddc", :at => 1
      should_match "zadcasdf", :at => 1
      should_match "zacasdfacg", :at => 1

      should_not_match "ac"
      should_not_match "abddddd"
    end

    describe "/ab+c/" do
      should_match "abc", :at => 0
      should_match "abbbbbbbbbbbbc", :at => 0
      should_match "abbc", :at => 0

      should_not_match "zacasdfacg"
      should_not_match "zabdddddc"
      should_not_match "zadcasdf"
      should_not_match "abddddd"
    end

    describe "/<.+>/" do
      should_match "<em>foo", :at => 0
      should_match "<em>foo</em>", :at => 0
    end    
  end

  describe "0 or 1 occurrence" do
    describe "/ab?c/" do
      should_match "abc", :at => 0
      should_match "ac", :at => 0

      should_not_match "abbc"
    end

    describe "/<.+?>/" do
      should_match "<e>", :at => 0
      should_match "<em>foo", :at => 0
      should_match "<em>foo</em>", :at => 0

      should_not_match "<>"
    end
  end

  describe "mixing modifiers" do
    describe "/a+bc*d/" do
      should_match "abcd", :at => 0
      should_match "aaaabcd", :at => 0
      should_match "aaaabccccccccd", :at => 0
      should_match "aaaabd", :at => 0

      should_not_match "bcd"
      should_not_match "aaabbbbbcd"
    end

    describe "/a*.c+d/" do
      should_match "abcd", :at => 0
      should_match "aaaabcd", :at => 0
      should_match "aaaabccccccccd", :at => 0
      should_match "bcd", :at => 0

      should_not_match "aaaabd"
      should_not_match "aaabbbbbcd"
    end
  end

end