require "uri"
require "net/http"
require 'nokogiri'
require 'open-uri'
require 'json'
require 'twitter'
require 'faraday'
require 'faraday/request/multipart'

class TimelinesController < ApplicationController
  @@consumer_secret = "YbhyKkfgPA8bK1UrWVIKxaUkDcm5nnGk5QLdKue9k"
  @@consumer_key =  "mQbKmq0yNCpDpvEEQvwGrw"
  def create  
    output_params = {}
    output_params["oauth_token"] = "447737360-mwOPhkQ2skhArUgv9fVDW4S7Vu484OF9rTkg8bxG"
    output_params["oauth_token_secret"] = "KKR6stuigeuMEvSvPRdC8Q4Ybi1cSSTDPDUXlmriG9saU"
    client = get_auth_client(output_params)
    response = client.post("https://api.twitter.com/1.1/beta/timelines/custom/create.json", params={:name => "newstest"})
    Rails.logger.info(response)
    render :json => response.to_json
  end

  def destroy

  end

  def update

  end

  def add
    
    x = make_request()
    client = get_auth_client()

    x["data"]["tweets"].reverse_each do |tweet|
      Rails.logger.info(tweet["tweet_id"])
      response = client.post("/1.1/beta/timelines/custom/add.json", params={:tweet_id => tweet["tweet_id"].to_s, :id => "custom-467906368129609729"})
      Rails.logger.info(response)
    end  
    render :json => {:success => 'Timeline updated'}
  end

  def remove
  end

  def curate
    x = make_request()
    client = get_auth_client()
    header_info = {}
    content_type_info = {}
    content_type_info['content-type'.to_sym] = 'application/json'
    header_info[:headers] = content_type_info
  	client.connection_options = header_info

    client.middleware = Faraday::RackBuilder.new do |faraday|
      #send application/json in post
      faraday.request :json
      # Checks for files in the payload, otherwise leaves everything untouched
      #faraday.request :multipart
      # Encodes as "application/x-www-form-urlencoded" if not already encoded
      faraday.request :url_encoded
      # Handle error responses
      faraday.response :raise_error
      # Parse JSON response bodies
      faraday.response :parse_json
      # Set default HTTP adapter
      faraday.adapter :net_http
    end

    request_data = {}
    request_data["id"] = "custom-467906368129609729"
    request_data["changes"] = []
    
    x["data"]["tweets"].reverse_each do |tweet|
      temp = {}
      temp["op"] = "add"
      temp["tweet_id"] = tweet["tweet_id"].to_s
      request_data["changes"].push(temp)
    end  
    Rails.logger.info(request_data)
    response = client.post("/1.1/beta/timelines/custom/curate.json", request_data)
    Rails.logger.info(response)
    render :json => {:success => 'Curation Timeline updated'}

  end
  
  def get_auth_client()

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = @@consumer_key
      config.consumer_secret     = @@consumer_secret
      config.access_token        = "447737360-mwOPhkQ2skhArUgv9fVDW4S7Vu484OF9rTkg8bxG"
      config.access_token_secret = "KKR6stuigeuMEvSvPRdC8Q4Ybi1cSSTDPDUXlmriG9saU"
    end
    client
  end  

  def make_request()
    search_url = "/tweet-store/index.php/api/TweetsUnique/get?&low=750&high=1000&size=50&top=0&q=&uniqueUser=true&country=in&screen_name=&topic=&in_reply_to_status_id="
    x = "{}"
    begin
      http = Net::HTTP.new("54.254.80.93")
      http.read_timeout = 5
      resp = http.get(search_url)
      x = JSON.parse resp.body
    #  Rails.logger.info(x)
    rescue Exception=>e
      Rails.logger.info("ElasticSearch Down")
      x = '{"found" : "error"}'
    rescue Net::ReadTimeout => e
      Rails.logger.info("ElasticSearch Read Timeout")
      x = '{"found" : "error"}'      
    end 
    x
  end
end