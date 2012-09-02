require 'spec_helper'

describe "regex matching" do
  subject { regex_engine }
  let(:regex_engine) { MyRegex.new(pattern) }

  describe "/a/" do
    let(:pattern){ "/a/" }
    it { should have_match("a") }
  end

  describe "/abc/" do
    let(:pattern){ "/abc/" }
    it { should have_match("abc") }
    it { should have_match("zabc") }
  end

  describe "/a.c/" do
    let(:pattern){ "/a.c/" }
    it { should have_match("abc") }
    it { should have_match("zabc") }
    it { should have_match("zadcasdf") }
  end


end