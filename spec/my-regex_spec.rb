require 'spec_helper'

describe "regex matching" do
  subject { regex_engine }
  let(:regex_engine) { MyRegex.new(pattern) }

  describe "/a/" do
    let(:pattern){ "/a/" }
    it { should have_match("a") }
  end

end