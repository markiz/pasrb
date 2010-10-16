require 'base64'
require 'openssl'
require 'cgi'

require 'rubygems'
require 'mechanize'
require 'xmlsimple'

class PAS
  # Your api key
  attr_accessor :api_key

  # Your api member id (for remote authentication)
  attr_accessor :api_member_id
  
  # api token for querying, set it if you know it or let it be auto-requested
  attr_writer :api_token


  
  def initialize(api_site, api_key, api_token = nil, api_member_id = nil)
    self.api_site      = api_site
    self.api_key       = api_key
    self.api_token     = api_token
    self.api_member_id = api_member_id
  end

  # Site that is using the PAS api
  def api_site
    @api_site
  end
  
  def api_site=(value)
    @api_site = value =~ /^https:\/\// ? value : "https://#{value}"
  end

  
  def request_signature(uri, method = "GET", timestamp = Time.now.to_i)
    payload = api_token.to_s + method + uri + timestamp.to_s
    signature = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA1.new, api_key, payload)
    CGI::escape(Base64.encode64(signature).chomp)
  end
  
  def api_token
    @api_token ||= request_api_token
  end
  
  def get_member_trackers_stats(start_date, end_date)
    @member_tracker_stats ||= {}
    @member_tracker_stats[start_date] ||= {}
    @member_tracker_stats[start_date][end_date] ||= get_member_trackers_stats!(start_date, end_date)
  end
  
  def get_member_trackers_stats!(start_date, end_date)
    start_date = start_date.strftime("%Y-%m-%d")
    end_date   = end_date.strftime("%Y-%m-%d")
    response = xml_to_hash(make_request("/publisher_members/#{api_member_id}/stats.xml", "GET", {:start_date => start_date, :end_date => end_date}))
    trackers = response["statistics"][0]["member_trackers"][0]["member_tracker"]
    trackers.inject({}) do |result, tracker|
      id = tracker["id"][0].to_i
      result[id] = {
        :identifier    => tracker["identifier"][0],
        :poker_room_id => tracker["poker_room_id"][0],
        :poker_room    => tracker["poker_room"][0],
        :mgr           => tracker["mgr"][0].to_f,
        :rakeback      => tracker["rakeback"][0].to_f
      }
      result[id.to_s] = result[id]
      result[tracker["identifier"][0]] = result[id]
      result
    end
  rescue
    nil
  end
  
  def get_member_tracker_stats(identifier, start_date, end_date)
    trackers = get_member_trackers_stats(start_date, end_date)
    trackers ? trackers[identifier] : nil
  rescue
    nil
  end
  
  def create_member_tracker(identifier, website_offer_id)
    new_member_tracker = {:member_tracker => {:identifier => identifier, :website_offer_id => website_offer_id}}
    response = make_request("/publisher_members/#{api_member_id}/publisher_member_trackers.xml", "POST", hash_to_xml(new_member_tracker))
    response = xml_to_hash(response)["member_tracker"][0]
    result = {}
    result[:affiliate_id]         = response["affiliate_id"][0]["content"].to_i
    result[:id]                   = response["id"][0]["content"].to_i
    result[:identifier]           = response["identifier"][0]
    result[:member_rakeback_rate] = response["member_rakeback_rate"][0]
    result[:poker_room_id]        = response["poker_room_id"][0]
    result
  rescue
    nil
  end
#protected
  def xml_to_hash(xml)
    XmlSimple.xml_in(xml, 
      'forcearray'   => true, 
      'forcecontent' => false, 
      'keeproot'     => true
    )
  end
  
  def hash_to_xml(hash)
    XmlSimple.xml_out(hash,
      'keeproot' => true
    )
  end

  def request_api_token
    login_data = {:member => api_member_id}
    response = make_request("/remote_auth.xml", "POST", hash_to_xml(login_data), false)
    xml_to_hash(response)["remote_auth_token"][0]
  rescue
    nil
  end
  
  def new_request
    Mechanize.new
  end
  
  def make_request(uri, method, payload = {}, signed = true)
    request = new_request

    query_params = if signed
      timestamp = Time.now.to_i
      {
        :timestamp => timestamp,
        :api_token => api_token,
        :signature => request_signature(uri, method, timestamp) 
      }
    else
      {}
    end
    
    case method
    when "GET"
      request.get(api_site + uri, Mechanize::Util.build_query_string(payload.merge(query_params))).body
    when "POST"
      request.post(api_site + uri + "?" + Mechanize::Util.build_query_string(query_params), payload).body
    else
      nil
    end
  end
end