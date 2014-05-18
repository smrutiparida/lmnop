require "uri"
require "net/http"
require 'nokogiri'
require 'open-uri'
require 'json'
require 'twitter'

class TimelinesController < ApplicationController
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
    output_params = {}
    output_params["oauth_token"] = "447737360-mwOPhkQ2skhArUgv9fVDW4S7Vu484OF9rTkg8bxG"
    output_params["oauth_token_secret"] = "KKR6stuigeuMEvSvPRdC8Q4Ybi1cSSTDPDUXlmriG9saU"
    client = get_auth_client(output_params)
    
    #Rails.logger.info(x["data"]["tweets"])

    x["data"]["tweets"].each do |tweet|
      Rails.logger.info(tweet["tweet_id"])
      response = client.post("https://api.twitter.com/1.1/beta/timelines/custom/add.json", params={:tweet_id => tweet["tweet_id"].to_s, :id => "custom-467906368129609729"})
      Rails.logger.info(response)
    end  
  end

  def remove
  end

  def curate
  	
  end
  
end