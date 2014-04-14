require "uri"
require "net/http"
require 'nokogiri'
require 'open-uri'
require 'json'

class TweetsController < ApplicationController
  def index
  end

  def auth
    #send a post request
    twitter_url = "https://api.twitter.com/oauth/request_token/"
    post_params = {}
    post_params['oauth_version'] = "1.0"
    post_params['oauth_timestamp'] = Time.now.to_i.to_s
    post_params['oauth_signature_method'] = 'HMAC-SHA1'
    post_params['oauth_callback'] = URI::encode('http://lmnopapp.com/tweets/my/')
    post_params['oauth_consumer_key'] = "bNEQCVbQ5G5fm1x0TTuWhCYAR"
    post_params['oauth_nonce'] = rand(10 ** 30).to_s.rjust(30,'0')
    post_params['oauth_signature'] = "POST&" + URI::encode(twitter_url) + "&"
    data = "OAuth " + post_params.map{|k,v| "#{k}=#{v}"}.join(',')

    
    uri = URI.parse(twitter_url)

    initheader = {"Accept"=> "*/*","Authorization" => data}

    http = Net::HTTP.new(uri.host,uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
    
    resp = http.post(uri.path, data, initheader)

    print resp.body

    #https://api.twitter.com/oauth/authenticate?oauth_token=NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0
    
  end

end
