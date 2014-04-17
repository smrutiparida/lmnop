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
      session.delete(:last_call)
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
  end
  
  
  def offline
    #render :json => {}, :status => :ok unless session[:user]
    cache = true
    status = 200
    tweet_list = []
    frequency_data = {}

    unless session[:last_call] and  (Time.now.to_i - session[:last_call] ) < 90
      if(session[:user])
        output_params = session[:user]  
        client = get_auth_client(output_params)
        all_tweets = client.home_timeline({:count => 200})
        all_tweets.each{ |tweet| tweet_list.push({ :user_id => tweet.user.id, :followers_count => tweet.user.followers_count, :rank => tweet.user.followers_count, :tweet_id => tweet.id ,:profile_image_url => tweet.user.profile_image_url.to_s, :name => tweet.user.name, :screen_name => tweet.user.screen_name, :created_at => tweet.created_at, :tweet_text => tweet.text,:in_reply_to_status_id => tweet.in_reply_to_status_id})}

        highest_fc = 0
        lowest_fc = 100000000
        tweet_list.each do |x|
          highest_fc = x[:rank] if x[:rank] > highest_fc
          lowest_fc = x[:rank] if x[:rank] < lowest_fc
        end
      
        lowest_rank = 1
        highest_rank = 1000
        tweet_list.each do |x|         
          num = (lowest_rank + (x[:followers_count] - lowest_fc) / ((highest_fc - lowest_fc)/(highest_rank - lowest_rank)))
          x[:rank] = num.ceil
        #  logger.info("before ceil:" + num.to_s + " follower count:" + x[:followers_count].to_s + "  rank:" + x[:rank].to_s)
        end  
      
        tweet_map = tweet_list.group_by{ |s| s[:screen_name] }
        tweet_map.each { |k,v| frequency_data[k] = v.length}
        session[:last_call] = Time.now.to_i
        status = 200
        cache = false
      else
        status = 403  
      end
    end    

    render :json => {:facets => frequency_data, :tweets => tweet_list, :cache=> cache}, :status => status
  end  

  def reply
    status = 403
    message = ""
    return_type = true

    if session[:user]
      output_params = session[:user]
      client = get_auth_client(output_params)
      begin
        client.update(params[:text],{:in_reply_to_status_id => params[:id].to_i})
      rescue Twitter::Error::Unauthorized
        message ="Authorization failed. Login again."
        return_type = false
      end  
      status = 200
    else
      status = 403  
    end  
    render :json => {:success => return_type, :message => message }, :status => status
  end
  
  
  def retweet
    status = 403
    message = ""
    return_type = true

    if session[:user]
      output_params = session[:user]
      client = get_auth_client(output_params)
      id_arr = [ params[:id].to_i]
      begin 
        client.retweet(id_arr)
      rescue Twitter::Error::Unauthorized
        message = "Authorization failed. Login again."
        return_type = false
      end 
      status = 200
    else
      status = 403
    end  

    render :json => {:success => return_type, :message => message} , :status => status
  end
  
  def favorite
    status = 403
    message = ""
    return_type = true

    if session[:user]
      output_params = session[:user]
      client = get_auth_client(output_params)
      id_arr = [ params[:id].to_i]
      begin 
        params[:is_favorite] ? client.unfavorite(id_arr) : client.favorite(id_arr)  
      rescue Twitter::Error::Unauthorized
        message = "Authorization failed. Login again."
        return_type = false
      end 
      status = 200
    else
      status = 403
    end
    
    render :json => {:success => return_type, :message => message }, :status => status
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
  
  private 

  def get_auth_client(output_params)

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = @@consumer_key
      config.consumer_secret     = @@consumer_secret
      config.access_token        = output_params["oauth_token"]
      config.access_token_secret = output_params["oauth_token_secret"]
    end
    client
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
