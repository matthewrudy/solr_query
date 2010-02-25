require File.dirname(__FILE__) + '/spec_helper'

module ActiveRecord ; class Base ; end ; end
class Organisation < ActiveRecord::Base
  def initialize(id)
    @id = id
  end
  attr_reader :id
end

describe SolrQuery do
  describe "build" do
    before(:each) do
      @record = Organisation.new(45)
      @it = SolrQuery
      
      @backslash = '\\'
      @escaped_backslash = @backslash*2 # backslashes are difficult to work with
    end
    
    it "should leave multi-word keywords intact" do
      @it.build(:keyword => "abc def").should == "abc def"
    end
    
    it "should default to giving out an empty string" do
      @it.build().should == ""
    end
    
    it "should join an array keyword with ORs" do
      @it.build(:keyword => ["abc", 23, @record]) \
        .should == "abc OR 23 OR 45"
    end
    
    it "should lowercase keywords" do
      @it.build(:keyword => "SOMETHING mostly UPPER CAse") \
        .should == "something mostly upper case"
    end
    
    it "should lowercase an array of keywords, but not the ORs" do
      @it.build(:keyword => ["SOMETHING", "mostly", "UPPER", "CAse"]) \
        .should == "something OR mostly OR upper OR case"
    end
    
    it "should join an array field with ORs" do
      @it.build(:someth => ["abc", 23, @record]) \
        .should == "someth:(abc OR 23 OR 45)"
    end
    
    it "should add a 'NIL' if given an empty array as a condition" do
      @it.build(:empty => []) \
        .should == "empty:(NIL)"
    end

    it "should find everything if given an empty array as keyword" do
      @it.build(:keyword => []) \
        .should == ""
    end
    
    it "should ignore the keyword field if given as nil" do
      @it.build(:keyword => nil, :something => "else") \
        .should == "something:(else)"
    end
    
    it "should ignore the keyword field if given as empty" do
      @it.build(:keyword => "   ", :something => "else") \
        .should == "something:(else)"
    end
    
    it "should let us define a string with an OR statement in" do
      @it.build(:keyword => "fire OR theft", :something => "else") \
        .should == "(fire OR theft) AND something:(else)"
    end
    
    it "should make a Record into its id" do
      @it.build(:keyword => @record, :record => @record).should == "45 AND record:(45)"
    end

    it "should ignore a nil field" do
      @it.build(:nilly => nil, :truey => true).should == "truey:(true)"
    end
    
    it "should default if just given nils" do
      @it.build(:nilly => nil, :nully => nil, :keyword => nil).should == ""
    end
    
    it 'should escape any \ ' do
      @it.build(:keyword => @backslash+" yeah"+@backslash+' '+@backslash+'    ', :something => 'a '+@backslash+'ey'+@backslash) \
        .should == @escaped_backslash+' yeah'+@escaped_backslash+' '+@escaped_backslash+' AND something:(a '+@escaped_backslash+'ey'+@escaped_backslash+')'
    end
    
    # this is a magical set of specs, that may be fragile - so we'll do a less magic version in a mo
    [ '+', '-', '!', '(', ')', ':', ';', '^', '[', ']', '{', '}', '~', '*', '?' ].each do |char|
      it "should escape any #{char}" do
        @it.build(:keyword => "#{char} yeah#{char} #{char}   ", :something => "a #{char}ey#{char}").should == "\\#{char} yeah\\#{char} \\#{char} AND something:(a \\#{char}ey\\#{char})"
      end
    end
    
    it 'should escape values in an array correctly' do
      @it.build(:id => ['User:1', 'User:2']) \
        .should == 'id:(User\:1 OR User\:2)'
    end
    
    it "should avoid matching anything if given an empty array as a value" do
      @it.build(
        :keyword => ["dont match", "something", "real"], :if_weve_got_a => []
        ).should == 'dont match OR something OR real AND if_weve_got_a:(NIL)'
    end
    
    it "should escape lucene special characters" do
      @it.build(:keyword => '  a* in the(sky)?  ', :something => 'makes {little} ~ferrets die! ').should == 'a\* in the\(sky\)\? AND something:(makes \{little\} \~ferrets die\!)'
    end
    
    it "should convert a range to a solr_range" do
      @it.build(:range => "abc".."def"
      ).should == "range:([abc TO def])"
    end
    
    it "should convert a range hash to a solr_range" do
      @it.build(:range => {:min => "abc", :max => "def"}
      ).should == "range:([abc TO def])"
    end
    
    it "should convert a >= range hash to a solr_range" do
      @it.build(:range => {:min => "abc"}
      ).should == "range:([abc TO *])"
    end
    
    it "should convert a <= range hash to a solr_range" do
      @it.build(:range => {:max => "def"}
      ).should == "range:([* TO def])"
    end
    
    it "should convert an empty hash to a wild solr_range" do
      @it.build(:range => {}
      ).should == "range:([* TO *])"
    end
  end
end