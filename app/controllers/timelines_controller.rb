require 'active_support/all'
class TimelinesController < ApplicationController

  def index
    p = Time.now.in_time_zone('Kolkata')
    #request.remote_ip was awake 
    session[:awake][request.remote_ip] = p.hour.to_s + ":" + p.minutes.to_s
    render :json => session[:awake].to_json
  end  
  
end