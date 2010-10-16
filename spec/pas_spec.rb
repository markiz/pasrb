require 'spec_helper'

describe PAS do
  def stub_request(content)
    subject.stub!(:new_request).and_return(mock("Request", :get => mock("Response", :body => content), :post => mock("Response", :body => content)))
  end
  
  subject { PAS.new("exampletracker.com", "FGSFDS", "WTFOMG") }
  
  describe "initialization" do
    it "should set api site from arguments" do
      PAS.new("https://exampletracker.com", "").api_site.should == "https://exampletracker.com"
    end
    
    it "should prepend https:// to url" do
      PAS.new("exampletracker.com", "").api_site.should == "https://exampletracker.com"
    end
    
    it "should set api key from arguments" do
      PAS.new("", "FGSFDS").api_key.should == "FGSFDS"
    end
    
    it "should optionally accept api token" do
      PAS.new("", "", "WTF").api_token.should == "WTF"
    end
    
    it "should optionally accept member id" do
      PAS.new("", "", nil, 1234).api_member_id.should == 1234
    end
  end
  
  describe "#request_signature" do
    subject { PAS.new("exampletracker.com", "BaEc8f13QlXgjQd4fBQ") }
    let(:method)    { "GET" }
    let(:uri)       { "/publisher_members/404043.xml" }
    let(:timestamp) { 1276980199 }
    let(:api_token) { "143aec8f13dfcc6cb364e6a9c9ff4bb0" }

    before(:each) do 
      Time.stub!(:now).and_return(Time.at(timestamp))
      subject.api_token = api_token
    end

    it "should generate valid signature for given params" do
      subject.request_signature(uri, method).should == "3gc17tMRqcXHxFKxBEdheCYfb0Q%3D"
    end
    
    it "should accept timestamp as an optional argument" do
      subject.request_signature(uri, method, timestamp).should == "3gc17tMRqcXHxFKxBEdheCYfb0Q%3D"
    end
  end
  
  describe "#api_token" do
    subject { PAS.new("https://example.com", "") }
    it "should use given api token if given" do
      subject.api_token = "WTFomg"
      subject.api_token.should == "WTFomg"
    end
    
    it "should get api token from API request" do
      stub_request('<?xml version="1.0" encoding="UTF-8"?><remote_auth_token>HTTPS_RESPONSE_TOKEN</remote_auth_token>')
      subject.api_token.should == "HTTPS_RESPONSE_TOKEN"
    end
    
    it "should return nil if some terrible, terrible error happens" do
      stub_request('<invalid></xml>')
      subject.api_token.should == nil      
    end
  end
  
  describe "#get_member_trackers_stats" do
    before(:each) { 
      stub_request('<?xml version="1.0" encoding="UTF-8"?>
                   <statistics start_date="2010-08-01" end_date="2010-08-18">
                    <member_id>12345</member_id>
                      <mgr>484.91</mgr>
                       <rakeback>218.21</rakeback>
                      <member_trackers type="array">
                       <member_tracker>
                        <id>6</id>
                        <identifier>qq124</identifier>
                        <poker_room_id>293</poker_room_id>
                        <poker_room>Poker Heaven</poker_room>
                        <mgr>484.91</mgr>
                        <rakeback>218.21</rakeback>
                       </member_tracker>
                      <member_tracker>
                        <id>2195</id>
                        <identifier>qq1244343</identifier>
                        <poker_room_id>293</poker_room_id>
                        <poker_room>Poker Heaven</poker_room>
                        <mgr>0</mgr>
                        <rakeback>0</rakeback>
                       </member_tracker>
                     </member_trackers>
                    </statistics>') 
    }
    
    it "should parse out members" do
      members = subject.get_member_trackers_stats(Date.parse("2010-08-01"), Date.parse("2010-08-18"))
      members[6][:identifier].should == "qq124"
      members[2195][:identifier].should == "qq1244343"
      members["qq124"].should == members[6]
    end
    
    it "should return nil on terrible, terrible failures" do
      stub_request("<invalid></xml>")
      subject.get_member_trackers_stats(Date.parse("2010-08-01"), Date.parse("2010-08-18")).should == nil
    end
  end
  
  describe "#get_member_tracker_stats" do
    before(:each) {
      stub_request('<?xml version="1.0" encoding="UTF-8"?>
                   <statistics start_date="2010-08-01" end_date="2010-08-18">
                    <member_id>12345</member_id>
                      <mgr>484.91</mgr>
                       <rakeback>218.21</rakeback>
                      <member_trackers type="array">
                       <member_tracker>
                        <id>6</id>
                        <identifier>qq124</identifier>
                        <poker_room_id>293</poker_room_id>
                        <poker_room>Poker Heaven</poker_room>
                        <mgr>484.91</mgr>
                        <rakeback>218.21</rakeback>
                       </member_tracker>
                      <member_tracker>
                        <id>2195</id>
                        <identifier>qq1244343</identifier>
                        <poker_room_id>293</poker_room_id>
                        <poker_room>Poker Heaven</poker_room>
                        <mgr>0</mgr>
                        <rakeback>0</rakeback>
                       </member_tracker>
                     </member_trackers>
                    </statistics>') 
    }
    
    it "should use members stats for specific member" do
      subject.get_member_tracker_stats("qq124", Date.parse("2010-08-01"), Date.parse("2010-08-18"))[:rakeback].should == 218.21
    end
   
    it "should return nil on terrible, terrible failures" do
      stub_request("<invalid></xml>")
      subject.get_member_tracker_stats("qq124", Date.parse("2010-08-01"), Date.parse("2010-08-18")).should == nil
    end 
  end
  
  describe "#create_member_tracker" do
    before(:each) { 
                    stub_request('<?xml version="1.0" encoding="UTF-8"?>
                                  <member_tracker>
                                    <affiliate_id type="integer">6</affiliate_id>
                                    <created_at type="datetime">2010-07-09T13:15:47-05:00</created_at>
                                    <id type="integer">120070</id>
                                    <identifier>NEWTESTRACKER</identifier>
                                    <member_id type="integer">222384334</member_id>
                                    <poker_room_id type="integer">6</poker_room_id>
                                    <signup_url>http://www.absolutepoker.com/main.asp?host=1751</signup_url>
                                    <website_id type="integer">4201</website_id>
                                    <member_rakeback_rate>30%</member_rakeback_rate>
                                  </member_tracker>') 
                  }
    let(:identifier) { "NEWTESTRACKER" }
    let(:website_offer_id) { 6 }
    
    it "should send a post request creating a member tracker" do
      response = subject.create_member_tracker(identifier, website_offer_id)
      response[:id].should                   == 120070
      response[:identifier].should           == "NEWTESTRACKER"
      response[:member_rakeback_rate].should == "30%"
    end
    
    it "should return nil on terrible, terrible failures" do
      stub_request("<invalid></xml>")
      subject.create_member_tracker(identifier, website_offer_id).should == nil
    end
  end
end