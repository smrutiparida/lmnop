require 'active_support/all'
class TimelinesController < ApplicationController

  def index
    p = Time.now.in_time_zone('Kolkata')
    #request.remote_ip was awake 
    session[:awake] = {} if session[:awake].nil?
    Rails.logger.info(request.remote_ip)
    session[:awake][request.remote_ip] =  p.hour.to_s + ":" + p.min.to_s
    render :json => session[:awake].to_json
  end  
  
end