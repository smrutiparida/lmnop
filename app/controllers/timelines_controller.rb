require 'active_support/all'
class TimelinesController < ApplicationController

  def index
    p = Time.now.in_time_zone('Kolkata')
    text = "Not the right time to know this."
    #if p.hour.to_i < 8 or p.hour.to_i > 21 
    #request.remote_ip was awake 
    $all_users = {} if $all_users.nil?
    
    name =  request.remote_ip == "49.205.92.21" ? "Smruti" : "Natarajan"
    $all_users[name] =  p.hour.to_s + ":" + p.min.to_s  
    text = ""
    $all_users.each { |key,val| text += key + " was awake till " + val + ", "}
    #end  
    render :text => text
  end  

  def show
    text = ""
    unless $all_users.nil?
      $all_users.each { |key,val| text += key + " was awake till " + val + ", "}
    end  
    render :text => text
  end
  
end