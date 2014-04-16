require "uri"
require "net/http"
require 'nokogiri'
require 'open-uri'
require 'json'
require 'twitter'

class TweetsController < ApplicationController
  @@consumer_secret = "Fhtou0sRRMw5jaGd6TDNAY25q0pvX0kuWhUG12SuZZIg7sVcA9"
  @@consumer_key =  "bNEQCVbQ5G5fm1x0TTuWhCYAR"

  def index
  end
  
  def my
    return redirect_to '/tweets/auth' unless session[:user] or (params["oauth_token"] and params["oauth_verifier"])

    if session[:user]
      output_params = session[:user]
    else  
     
      twitter_url = "https://api.twitter.com/oauth/access_token"
      post_params = get_params()
      post_params["oauth_token"] = params["oauth_token"]
      post_params["oauth_verifier"] = params["oauth_verifier"]
      
      signature_base_string = signature_base_string("POST", twitter_url, post_params)

      logger.info(signature_base_string) 

      post_params['oauth_signature'] = url_encode(sign(@@consumer_secret + '&' + post_params["oauth_token"] , signature_base_string))
      
      post_params.delete("oauth_verifier")

      data = "OAuth " + post_params.map{|k,v| "#{k}=\"#{v}\""}.join(', ')

      logger.info(data)
      
      uri = URI.parse(twitter_url)

      initheader = {"Content-type"=> "application/x-www-form-urlencoded","Accept"=> "*/*","Authorization" => data}
      http = Net::HTTP.new(uri.host,uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
      
      resp = http.post(uri.path, "oauth_verifier=" + params["oauth_verifier"] , initheader)

      logger.info(resp.body)

      ##now set a infinite cookie and get the tweeer timeline
      output_params = split_params(resp.body)

      session["user"]= output_params


    end
  
    client = get_auth_client(output_params)

    
    all_tweets = client.home_timeline({:count => 200})

    #all_tweets = tweet_list.slice("id", "user", "created_at", "text")

    #all_tweets.each |tweet| do
    #  tweet.user.slice("profile_image_url","name","screen_name",)
    #  @tweet_list.push({ :count => tweet.length, :id=> tweet[0].id ,:profile_image_url => tweet.user.profile_image_url, :name => tweet[0].user.name, :screen_name => tweet[0].user.screen_name, :created_at => tweet[0].created_at, :text => tweet[0].text})
    #end

    #tweet_map = all_tweets.group_by{ |s| s.user.screen_name }
    
    @tweet_list = []
    all_tweets.each{ |tweet| @tweet_list.push({ :tweet_id => tweet.id ,:profile_image_url => tweet.user.profile_image_url, :name => tweet.user.name, :screen_name => tweet.user.screen_name, :created_at => tweet.created_at, :tweet_text => tweet.text,:in_reply_to_status_id => tweet.in_reply_to_status_id})}
    #Rails.logger.info(@tweet_list.to_s)
    #oauth_token=19981747-JZP0uTpY9vUh5Y1wWdJI5otV8HiQcxAekgLzwDiZB&oauth_token_secret=G9JmY9SxpG66ylmZfRegwZQZ3WcY6wnokSnbLMfLaNs3q&user_id=19981747&screen_name=smrutiparida
  end  

  def reply
    if session[:user]
      output_params = session[:user]
      client = get_auth_client(output_params)
      client.update(params[:text],{:in_reply_to_status => params[:id]})
      render :json => {:success => true }, :status => :ok
    end  
  end
  
  
  def retweet
    if session[:user]
      output_params = session[:user]
      client = get_auth_client(output_params)
      id_arr = [ params[:id]]
      client.retweet(id_arr)
      Rails.logger.info("retweeted")
      render :json => {:success => true }, :status => :ok
    end  
    render :json => {:success => false} , :status => 403
  end
  
  def favorite
    render :json => {:success => true }, :status => :ok
  end

  def logout
    reset_session
    flash[:notice] = "You have successfully logged out."
    redirect_to "/tweets/index"
  end  

  def split_params(str)
    name_val = str.split('&')
    my_map = {}
    name_val.each do |x|
      output_params = x.split('=')
      my_map[output_params[0]] = output_params[1]
    end
    my_map  
  end

  def get_auth_client(output_params)

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = @@consumer_key
      config.consumer_secret     = @@consumer_secret
      config.access_token        = output_params["oauth_token"]
      config.access_token_secret = output_params["oauth_token_secret"]
    end
    client
  end  
  
  def auth
      
    #send a post request
    
    #auth_token_secret ="TWgjxFgp7T0T6GwEv7jAO3FlXLuKKtjPOoaKRYeOWmTSG"
    twitter_url = "https://api.twitter.com/oauth/request_token"
    post_params = get_params()
    post_params['oauth_callback'] = url_encode('http://lmnopapp.com/tweets/my')
    
    signature_base_string = signature_base_string("POST", twitter_url, post_params)

    logger.info(signature_base_string)

    post_params['oauth_signature'] = url_encode(sign(@@consumer_secret + '&'  , signature_base_string))

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
    my_map = split_params(resp.body)

    redirect_to "https://api.twitter.com/oauth/authenticate?oauth_token=" + my_map["oauth_token"]
    
  end
  
  def get_params()
    post_params = {}
    post_params['oauth_version'] = "1.0"
    post_params['oauth_timestamp'] = Time.now.to_i.to_s
    post_params['oauth_signature_method'] = 'HMAC-SHA1'
    post_params['oauth_consumer_key'] = @@consumer_key
    post_params['oauth_nonce'] = rand(10 ** 30).to_s.rjust(30,'0')
    
    post_params
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
