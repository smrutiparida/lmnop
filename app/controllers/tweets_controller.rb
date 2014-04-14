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
    consumer_secret = "Fhtou0sRRMw5jaGd6TDNAY25q0pvX0kuWhUG12SuZZIg7sVcA9"
    auth_token_secret ="TWgjxFgp7T0T6GwEv7jAO3FlXLuKKtjPOoaKRYeOWmTSG"
    twitter_url = "https://api.twitter.com/oauth/request_token"
    post_params = {}
    post_params['oauth_version'] = "1.0"
    post_params['oauth_timestamp'] = Time.now.to_i.to_s
    post_params['oauth_signature_method'] = 'HMAC-SHA1'
    post_params['oauth_callback'] = url_encode('http://lmnopapp.com/tweets/my')
    post_params['oauth_consumer_key'] = "bNEQCVbQ5G5fm1x0TTuWhCYAR"
    post_params['oauth_nonce'] = rand(10 ** 30).to_s.rjust(30,'0')
    
    signature_base_string = signature_base_string("POST", twitter_url, post_params)

    logger.info(signature_base_string)

    post_params['oauth_signature'] = url_encode(sign(consumer_secret + '&'  , signature_base_string))

    data = "OAuth " + post_params.map{|k,v| "#{k}=\"#{v}\""}.join(', ')

    logger.info(data)
    
    uri = URI.parse(twitter_url)

    initheader = {"Accept"=> "*/*","Authorization" => data}

    http = Net::HTTP.new(uri.host,uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
    
    resp = http.post(uri.path, "" , initheader)

    logger.info(resp.body)
 
    #check if secret is fine and data is not compromised
    name_val = resp.body.split('&')
    my_map = {}
    name_val.each do |x|
      output_params = x.split('=')
      my_map[output_params[0]] = output_params[1]
    end 
    redirect_to "https://api.twitter.com/oauth/authenticate?oauth_token=" + my_map["oauth_token"]
    
  end
  
  def url_encode(string)
    CGI::escape(string)
  end
  
  def signature_base_string(method, uri, params)
    encoded_params = params.sort.collect{ |k, v| url_encode("#{k}=#{v}") }.join("%26")
    method + '&' + url_encode(uri) + '&' + encoded_params
  end
  
  def sign(key, base_string)
    digest = OpenSSL::Digest::Digest.new('sha1')
    hmac = OpenSSL::HMAC.digest(digest, key, base_string)
    Base64.encode64(hmac).chomp.gsub(/\n/, '')
  end

end
