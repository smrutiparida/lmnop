class ApplicationController < ActionController::Base
  protect_from_forgery
  #the below 2 is from smruti.parida@gmail.com . We got permission to brizztv account for custom timelines account. Hence creating new key and secret
  #@@consumer_secret = "ho9RwNBuOZ0EVJQ4BJtbYdwJJW4np47LgcclZVJJRZIwcxGRrI"
  #@@consumer_key =  "tM7jPwa7VW2agWKzauZALCmGY"
  @@consumer_secret = "6NGRDnZr5ESl5dW0bgVdDWBi7fxgjYRTVYNfbdTlifARzWwppK"
  @@consumer_key =  "oZ35s173qnlnlXAXV07Ng43Qa"
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
