require 'spec_helper'

describe PAS do
  def stub_request(content)
    subject.stub!(:new_request).and_return(mock("Request", :get => mock("Response", :body => content), :post => mock("Response", :body => content)))
  end
  
  subject { PAS.new("API_MEGA_KEY", "API_ZETA_TOKEN", "exampletracker.com") }
  
  describe "initialization" do
    it "should set api key from arguments" do
      PAS.new("FGSFDS", "").api_key.should == "FGSFDS"
    end
    
    it "should optionally accept api token" do
      PAS.new("", "WTF").api_token.should == "WTF"
    end
    
    it "should optionally set api site from arguments" do
      PAS.new("", "", "https://exampletracker.com").api_site.should == "https://exampletracker.com"
    end

    it "should prepend https:// to url" do
      PAS.new("","","exampletracker.com").api_site.should == "https://exampletracker.com"
    end

  end
  
  describe "#request_signature" do
    subject { PAS.new("BaEc8f13QlXgjQd4fBQ", "143aec8f13dfcc6cb364e6a9c9ff4bb0") }
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
  
  describe "#member_page_count" do
    subject { PAS.new("BaEc8f13QlXgjQd4fBQ", "143aec8f13dfcc6cb364e6a9c9ff4bb0") }
    before(:each) {
      stub_request("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<members current_page=\"1\" next_page=\"\" total_pages=\"98\" total_entries=\"0\">\n</members>\n")
    }
    it "should set itself from member list page" do
      subject.send(:member_page_count).should == 98
    end
    
    it "should return 0 on terrible, terrible failures" do
      stub_request("<invalid></xml>")
      subject.send(:member_page_count).should == 0
    end
  end

  describe "#member_page" do
    before(:each) {
      stub_request('<?xml version="1.0" encoding="UTF-8"?>
                    <members current_page="2" next_page="3" total_pages="74" total_entries="2943">
                      <member>
                        <id>26371</id>
                        <outside_id></outside_id>
                        <website_id>53</website_id>
                        <login>aurelius</login>
                        <email>aurelius@mail.ru</email>
                        <first_name>Marcus</first_name>
                        <last_name>Aurelius</last_name>
                        <referring_member_id></referring_member_id>
                        <address_1></address_1>
                        <address_2></address_2>
                        <aim></aim>
                        <skype></skype>
                        <phone></phone>
                        <yahoo></yahoo>
                        <city></city>
                        <state></state>
                        <zip_code></zip_code>
                        <country></country>
                        <created_at>2006-10-11 19:00:00 -0500</created_at>
                        <date_of_birth>1964-07-06</date_of_birth>
                        <gender></gender>
                      </member>
                      <member>
                        <id>26380</id>
                        <outside_id></outside_id>
                        <website_id>53</website_id>
                        <login>durachok</login>
                        <email>durachok@yandex.ru</email>
                        <first_name>Dumbo</first_name>
                        <last_name>Shmumbo</last_name>
                        <referring_member_id></referring_member_id>
                        <address_1></address_1>
                        <address_2></address_2>
                        <aim></aim>
                        <skype></skype>
                        <phone></phone>
                        <yahoo></yahoo>
                        <city></city>
                        <state></state>
                        <zip_code></zip_code>
                        <country></country>
                        <created_at>2006-10-12 19:00:00 -0500</created_at>
                        <date_of_birth></date_of_birth>
                        <gender></gender>
                      </member>
                    </members>
')
    }
    
    it "should parse members out of a member page" do
      members = subject.member_page(2)
      members[0][:id].should == 26371
      members[0][:login].should == "aurelius"
      members[0][:first_name].should == "Marcus"
      members[0][:last_name].should == "Aurelius"
    end
    
    it "should return empty error on failures" do
      stub_request("<invalid></xml>")
      subject.member_page(2).should == []
    end
  end
  
  
  describe "#all_members" do
    before(:each) {
      stub_request('<?xml version="1.0" encoding="UTF-8"?>
                    <members current_page="1" next_page="2" total_pages="2" total_entries="2">
                      <member>
                        <id>26371</id>
                        <outside_id></outside_id>
                        <website_id>53</website_id>
                        <login>aurelius</login>
                        <email>aurelius@mail.ru</email>
                        <first_name>Marcus</first_name>
                        <last_name>Aurelius</last_name>
                        <referring_member_id></referring_member_id>
                        <address_1></address_1>
                        <address_2></address_2>
                        <aim></aim>
                        <skype></skype>
                        <phone></phone>
                        <yahoo></yahoo>
                        <city></city>
                        <state></state>
                        <zip_code></zip_code>
                        <country></country>
                        <created_at>2006-10-11 19:00:00 -0500</created_at>
                        <date_of_birth>1964-07-06</date_of_birth>
                        <gender></gender>
                      </member>
                      <member>
                        <id>26380</id>
                        <outside_id></outside_id>
                        <website_id>53</website_id>
                        <login>durachok</login>
                        <email>durachok@yandex.ru</email>
                        <first_name>Dumbo</first_name>
                        <last_name>Shmumbo</last_name>
                        <referring_member_id></referring_member_id>
                        <address_1></address_1>
                        <address_2></address_2>
                        <aim></aim>
                        <skype></skype>
                        <phone></phone>
                        <yahoo></yahoo>
                        <city></city>
                        <state></state>
                        <zip_code></zip_code>
                        <country></country>
                        <created_at>2006-10-12 19:00:00 -0500</created_at>
                        <date_of_birth></date_of_birth>
                        <gender></gender>
                      </member>
                    </members>
    ')
    }
    
    it "should get all pages of members" do
      subject.should_receive(:member_page).with(1).and_return([])
      subject.should_receive(:member_page).with(2).and_return([])
      subject.all_members
    end
    
    it "should return an array with members" do
      subject.all_members[1][:first_name].should == "Dumbo"      
    end
    
    it "should return empty array on failures" do
      stub_request("<invalid></xml>")
      subject.all_members.should == []
    end
  end
  
  describe "#get_member_trackers" do
    before(:each) {
      stub_request('<?xml version="1.0" encoding="UTF-8"?>
                    <statistics start_date="2010-10-01" end_date="2010-10-31">
                      <member_id>26857</member_id>
                      <mgr>-0.39</mgr>
                      <rakeback>-0.13</rakeback>
                      <member_trackers type="array">
                        <member_tracker>
                          <id>9489</id>
                          <identifier>kit_the_kid</identifier>
                          <poker_room_id>5</poker_room_id>
                          <poker_room>UB.com</poker_room>
                          <mgr>0.00</mgr>
                          <rakeback>0.00</rakeback>
                        </member_tracker>
                        <member_tracker>
                          <id>9706</id>
                          <identifier>renevacio</identifier>
                          <poker_room_id>12</poker_room_id>
                          <poker_room>Sun Poker</poker_room>
                          <mgr>0.00</mgr>
                          <rakeback>0.00</rakeback>
                        </member_tracker>
                        <member_tracker>
                          <id>24308</id>
                          <identifier>KitVetrogon</identifier>
                          <poker_room_id>29</poker_room_id>
                          <poker_room>Full Tilt Poker</poker_room>
                          <mgr>-0.39</mgr>
                          <rakeback>-0.13</rakeback>
                        </member_tracker>
                        <member_tracker>
                          <id>25477</id>
                          <identifier>Alan_Dzazoev</identifier>
                          <poker_room_id>85</poker_room_id>
                          <poker_room>Minted Poker</poker_room>
                          <mgr>0.00</mgr>
                          <rakeback>0.00</rakeback>
                        </member_tracker>
                      </member_trackers>
                    </statistics>
      ')
    }
    
    it "should get all the member trackers for given member id" do
      trackers = subject.get_member_trackers(26857)
      trackers[0][:id].should == 9489
      trackers[0][:identifier].should == "kit_the_kid"
      trackers[1][:id].should == 9706
      trackers[1][:identifier].should == "renevacio"
    end
    
    it "should return empty array on failure" do
      stub_request("<invalid></xml>")
      subject.get_member_trackers(26857).should == []
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
    
    let(:member_id) { 12345 }
    
    it "should parse out members" do
      members = subject.get_member_trackers_stats(member_id, Date.parse("2010-08-01"), Date.parse("2010-08-18"))
      members.should have_exactly(2).items
      members[0][:poker_room_id].should == 293
      members[1][:poker_room_id].should == 293
    end
    
    it "should return nil on terrible, terrible failures" do
      stub_request("<invalid></xml>")
      subject.get_member_trackers_stats(member_id, Date.parse("2010-08-01"), Date.parse("2010-08-18")).should == nil
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
    
    let(:member_id) { 12345 }
    
    it "should use members stats for specific member" do
      subject.get_member_tracker_stats(member_id, "qq124", Date.parse("2010-08-01"), Date.parse("2010-08-18"))[:rakeback].should == 218.21
      subject.get_member_tracker_stats(member_id, 6, Date.parse("2010-08-01"), Date.parse("2010-08-18"))[:rakeback].should == 218.21
    end
   
    it "should return nil on terrible, terrible failures" do
      stub_request("<invalid></xml>")
      subject.get_member_tracker_stats(member_id, "qq124", Date.parse("2010-08-01"), Date.parse("2010-08-18")).should == nil
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
    let(:member_id) { 222384334 }
    it "should send a post request creating a member tracker" do
      response = subject.create_member_tracker(member_id, identifier, website_offer_id)
      response[:id].should                   == 120070
      response[:identifier].should           == "NEWTESTRACKER"
      response[:member_rakeback_rate].should == "30%"
    end
    
    it "should return nil on terrible, terrible failures" do
      stub_request("<invalid></xml>")
      subject.create_member_tracker(member_id, identifier, website_offer_id).should == nil
    end
  end
  
  describe "#website_offers" do
    before(:each) {
      stub_request('xml version="1.0" encoding="UTF-8"?>
                    <offers>
                    <offer>
                        <id>4881</id>
                        <poker_room_id>6</poker_room_id>
                        <poker_room_xml_url>https://publisher.pokeraffiliatesolutions.com/feeds/poker_rooms/absolute-poker.xml</poker_room_xml_url>
                        <slug>absolute-poker</slug>
                        <image_url>http://publisher.pokeraffiliatesolutions.com/images/offers/lg_6.gif</image_url>
                        <icon_url>http://publisher.pokeraffiliatesolutions.com/images/icons/icon_6.gif</icon_url>
                        <tny_image_url>http://publisher.pokeraffiliatesolutions.com/images/offers/tny_6.gif</tny_image_url>
                        <name>Absolute Poker</name>
                        <network>Cereus</network>
                        <direct_url>http://publisher.pokeraffiliatesolutions.com/outgoing/4881</direct_url>
                        <link>http://www.raketracker.ru/rakeback/absolute-poker.html</link>
                        <rb_player>30%</rb_player>
                        <stats>Daily</stats>
                        <sitebonus>150% up to $500</sitebonus>
                        <raketype>contributed</raketype>
                        <offer_type>Rakeback</offer_type>
                        <signup_code>RAKETRACK</signup_code>
                        <account_identifier>Screen Name</account_identifier>
                        <show_cookies_message>true</show_cookies_message>
                        <requires_preloaded_tracker>false</requires_preloaded_tracker>
                        <promotions>
                          <promotion>
                            <name>Cereus Rake Race</name>
                            <feed_url>https://publisher.pokeraffiliatesolutions.com/feeds/promotions/CEREUS.xml?type=rake_race</feed_url>
                          </promotion>
                        </promotions>
                      </offer>
                      <offer>
                        <id>34835</id>
                        <poker_room_id>85</poker_room_id>
                        <poker_room_xml_url>https://publisher.pokeraffiliatesolutions.com/feeds/poker_rooms/minted-poker.xml</poker_room_xml_url>
                        <slug>minted-poker</slug>
                        <image_url>http://publisher.pokeraffiliatesolutions.com/images/offers/lg_85.gif</image_url>
                        <icon_url>http://publisher.pokeraffiliatesolutions.com/images/icons/icon_85.gif</icon_url>
                        <tny_image_url>http://publisher.pokeraffiliatesolutions.com/images/offers/tny_85.gif</tny_image_url>
                        <name>Minted Poker</name>
                        <network>Everleaf Gaming</network>
                        <direct_url>http://publisher.pokeraffiliatesolutions.com/outgoing/34835</direct_url>
                        <link>http://www.raketracker.ru/rakeback/minted-poker.html</link>
                        <rb_player>40%</rb_player>
                        <stats>Monthly</stats>
                        <sitebonus>100% up to $400</sitebonus>
                        <raketype>contributed</raketype>
                        <offer_type>Rakeback</offer_type>
                        <signup_code>TrackRB</signup_code>
                        <account_identifier>Nickname</account_identifier>
                        <show_cookies_message>true</show_cookies_message>
                        <requires_preloaded_tracker>false</requires_preloaded_tracker>
                        <promotions>
                          <promotion>
                            <name>Minted Rake Chase</name>
                            <feed_url>https://publisher.pokeraffiliatesolutions.com/feeds/promotions/minted.xml?type=rake_chase</feed_url>
                          </promotion>
                        </promotions>
                      </offer>
                    </offers>')
    }
    
    it "should gather website offers from api" do
      website_offers = subject.website_offers(12345)
      website_offers[1][:id].should == 34835
      website_offers[1][:slug].should == "minted-poker"
    end
    
    it "should return empty array on failure" do
      stub_request("<invalid></xml>")
      subject.website_offers(12345).should == []
    end
  end

  describe "#websites" do
    before(:each) { stub_request('<?xml version="1.0" encoding="UTF-8"?>
                                  <websites>
                                    <website>
                                      <id>53</id>
                                      <name>&#1056;&#1077;&#1081;&#1082;&#1090;&#1088;&#1077;&#1082;&#1077;&#1088;</name>
                                      <domain_name>www.raketracker.ru</domain_name>
                                      <enabled>true</enabled>
                                    </website>
                                    <website>
                                      <id>211</id>
                                      <name>mirpokera</name>
                                      <domain_name>rakeback.mirpokera.com</domain_name>
                                      <enabled>true</enabled>
                                    </website>
                                  </websites>') }
    it "should return a list of websites" do
      websites = subject.websites
      websites.should have_exactly(2).items
      websites[1][:id].should == 211
      websites[1][:name].should == "mirpokera"
    end

    it "should return empty nil on failure" do
      stub_request("<invalid></xml>")
      subject.websites.should be_nil
    end
  end
  
end