require "uri"
require "net/http"
require 'nokogiri'
require 'open-uri'
require 'json'
require 'twitter'

class TimelinesController < ApplicationController
  def create
    return redirect_to '/tweets/auth' unless session[:user] or (params["oauth_token"] and params["oauth_verifier"])
    if session[:user]
      output_params = session[:user]
      client = get_auth_client(output_params)
      response = client.post("https://api.twitter.com/1.1/beta/timelines/custom/create.json", params={:name => "newstest"})
      Rails.logger.info(response)
      render :json => response.to_json
    end  
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