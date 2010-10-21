require 'base64'
require 'openssl'
require 'cgi'

require 'rubygems'
require 'mechanize'
require 'xmlsimple'

class PAS
  # Your api key
  attr_accessor :api_key

  # api token for querying, set it if you know it or let it be auto-requested
  attr_accessor :api_token
  
  

  
  def initialize(api_key, api_token, api_site = "publisher.pokeraffiliatesolutions.com")
    self.api_site      = api_site
    self.api_key       = api_key
    self.api_token     = api_token
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
  
  ## MEMBER LEVEL
  
  # List all members
  # That is a very request-heavy method, be afraid, be very afraid
  def list_all_members
    @all_members ||= list_all_members!
  end
  alias_method :all_members, :list_all_members
  
  def list_all_members!
    (1..member_page_count).inject([]) {|result, page| result + member_page(page) }    
  rescue
    []
  end
  
  # Returns member page count
  # @api private
  def member_page_count
    @member_page_count ||= member_page_count!
  end
  
  # @api private
  def member_page_count!
    result = xml_to_hash(make_request("/publisher_members.xml", "GET"))
    result["members"]["total_pages"].to_i
  rescue
    0
  end
  
  # Gets a single members page
  # @api private
  def member_page(page)
    result = xml_to_hash(make_request("/publisher_members.xml", "GET", {:page => page}))
    members = [result["members"]["member"]].flatten    
    symbolize_keys(members).map {|m| m[:id] = m[:id].to_i; m}
  rescue
    []
  end

  # Gets a list of all member trackers
  def get_member_trackers(member_id)
    result = xml_to_hash(make_request("/publisher_members/#{member_id}/stats.xml", "GET"))
    [result["statistics"]["member_trackers"]["member_tracker"]].flatten.map {|t| symbolize_keys(t) }.map {|t| t[:id] = t[:id].to_i; t }
  rescue
    []
  end
  
  # Gather stats for specific member for specific period of time
  # Warning: probably not page aware: didn't check that one
  def get_member_trackers_stats(member_id, start_date, end_date)
    @member_tracker_stats ||= {}
    @member_tracker_stats[member_id] ||= {}
    @member_tracker_stats[member_id][start_date] ||= {}
    @member_tracker_stats[member_id][start_date][end_date] ||= get_member_trackers_stats!(member_id, start_date, end_date)
  end
  
  def get_member_trackers_stats!(member_id, start_date, end_date)
    start_date = start_date.strftime("%Y-%m-%d")
    end_date   = end_date.strftime("%Y-%m-%d")
    response = xml_to_hash(make_request("/publisher_members/#{member_id}/stats.xml", "GET", {:start_date => start_date, :end_date => end_date}))
    trackers = [response["statistics"]["member_trackers"]["member_tracker"]].flatten
    trackers.inject([]) do |result, tracker|
      result << {
        :id            => tracker["id"].to_i,
        :identifier    => tracker["identifier"],
        :poker_room_id => tracker["poker_room_id"].to_i,
        :poker_room    => tracker["poker_room"],
        :mgr           => tracker["mgr"].to_f,
        :rakeback      => tracker["rakeback"].to_f
      }
    end
  rescue
    nil
  end
    
  def get_member_tracker_stats(member_id, tracker_id, start_date, end_date)
    trackers = get_member_trackers_stats(member_id, start_date, end_date)
    trackers ? trackers.detect {|t| t[:identifier] == tracker_id || t[:id] == tracker_id } : nil
  rescue
    nil
  end
  
  
  # Creates a member for given website offer  
  def create_member_tracker(member_id, identifier, website_offer_id)
    new_member_tracker = {"member_tracker" => {"identifier" => identifier, "website_offer_id" => website_offer_id}}
    response = make_request("/publisher_members/#{member_id}/publisher_member_trackers.xml", "POST", hash_to_xml(new_member_tracker))
    response = xml_to_hash(response)["member_tracker"]
    result = {}
    result[:affiliate_id]         = response["affiliate_id"]["content"].to_i
    result[:id]                   = response["id"]["content"].to_i
    result[:identifier]           = response["identifier"]
    result[:member_rakeback_rate] = response["member_rakeback_rate"]
    result[:poker_room_id]        = response["poker_room_id"]
    result
  rescue
    nil
  end
  
  # Returns array of website offers for given website id
  def website_offers(website_id)
    response = make_request("/website_offers.xml", "GET", {:website_id => website_id})
    response = [xml_to_hash(response)["offers"]["offer"]].flatten
    symbolize_keys(response).map {|o| o[:id] = o[:id].to_i; o }
  rescue
    []
  end
  alias_method :get_website_offers, :website_offers
  
#protected
  def xml_to_hash(xml)
    XmlSimple.xml_in(xml, 
      'forcearray'   => false, 
      'forcecontent' => false, 
      'keeproot'     => true
    )
  end
  
  def hash_to_xml(hash)
    XmlSimple.xml_out(hash,
      'keeproot' => true
    )
  end
  
  def new_request
    Mechanize.new
  end
  
  def make_request(uri, method, payload = {}, signed = true)
    request = new_request

    query_params = if signed
      timestamp = Time.now.to_i
      {
        :timestamp, timestamp,        
        :api_token, api_token,
        :signature, request_signature(uri, method, timestamp)
      }
    else
      {}
    end

    case method
    when "GET"
      request.get(api_site + uri + "?" + build_query_string(query_params.merge(payload))).body
    when "POST"
      request.post(api_site + uri + "?" + build_query_string(query_params), payload, "Content-Type" => "application/xml").body
    else
      nil
    end
  end


  #
  # Basically the same as the Mechanize::Util.build_query_string but without urlencode
  # (would have urlencoded it twice otherwise)
  #
  def build_query_string(params)
    params.map { |k,v|
      [k.to_s, v.to_s].join("=") if k
    }.compact.join('&')
  end
  
  # recursive key symbolization
  def symbolize_keys(arg)
    case arg
    when Array
      arg.map { |elem| symbolize_keys elem }
    when Hash
      Hash[
        arg.map { |key, value|  
          k = key.is_a?(String) ? key.to_sym : key
          v = symbolize_keys value
          [k,v]
        }]
    else
      arg
    end
  end
end