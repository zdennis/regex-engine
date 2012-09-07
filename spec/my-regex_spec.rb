require 'spec_helper'

describe "regex matching" do
  subject { regex_engine }
  let(:regex_engine) { MyRegex.new(pattern) }

  describe "/a/" do
    let(:pattern){ "/a/" }
    it { should have_match("a") }

    it { should_not have_match("b") }
  end

  describe "/abc/" do
    let(:pattern){ "/abc/" }
    it { should have_match("abc") }
    it { should have_match("zabc") }

    it { should_not have_match("bca") }
    it { should_not have_match("cba") }
    it { should_not have_match("ab.") }
  end

  describe "/a.c/" do
    let(:pattern){ "/a.c/" }
    it { should have_match("abc") }
    it { should have_match("zabc") }
    it { should have_match("zadcasdf") }

    it { should_not have_match("cbc") }
    it { should_not have_match("zabd") }
    it { should_not have_match("zadbca") }
  end

  describe "0 or more occurrences" do
    describe "/a.*c/" do
      let(:pattern){ "/a.*c/" }
      it { should have_match("ac") }
      it { should have_match("abc") }
      it { should have_match("abbc") }
      it { should have_match("zabdddddc") }
      it { should have_match("zadcasdf") }
      it { should have_match("zacasdfacg") }

      it { should_not have_match("abddddd") }
    end
  end

end