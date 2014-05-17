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
  end

  def remove
  end

  def curate
  	
  end
  
end