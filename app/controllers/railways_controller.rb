require "uri"
require "net/http"
require 'nokogiri'
require 'open-uri'
require 'json'

class RailwaysController < ApplicationController
  def pnr
  	begin
  	  captchaID, form_action = get_railway_data()
  	  data = construct_post_params(captchaID, params['q'])
  	  html_doc = query_railway_server(data, form_action)
      html_doc = Nokogiri::HTML(html_doc)

      availability_info_tables = html_doc.xpath("//table[@id='center_table']/tr")
      @final_list = []
      details = availability_info_tables.collect do |row|
        detail = {}
        [
	      [:berth, "td[@class='table_border_both'][2]/b/text()"],
	      [:status, "td[@class='table_border_both'][3]/b/text()"],
	    ].each do |name, xpath|
	      detail[name] = row.at_xpath(xpath).to_s.strip	
	      
        end
        @final_list.push(detail) unless detail[:berth].blank?
      end  
 	  rescue Exception=>e
      Rails.logger.info(e)
    end    
    render :json => @final_list.to_json
  end

  def profanity
    post_params = {}
    post_params['text'] = params['q']
    post_params['method'] = 'webpurify.live.check'
    post_params['api_key'] = 'a924c915b693f7f4ad97da6deca0fc56'
    post_params['format'] = 'json'
    post_params['lang'] = if params['lang'].blank? ? "en" : params['lang']
    data = post_params.map{|k,v| "#{k}=#{v}"}.join('&')

    uri = URI.parse('http://api1.webpurify.com/services/rest/')
    initheader = {"Content-type"=> "application/x-www-form-urlencoded", "Accept"=> "text/json"}
    http = Net::HTTP.new(uri.host,uri.port)
    resp = http.post(uri.path, data, initheader)
    json = JSON.parse resp.body
    if json['rsp']['@attributes']['stat'] != "ok"
      return :json =>'failure'
    end
      
    render :json => json['rsp']['found']
  end

  private
  
  
  def get_railway_data()
  	doc = Nokogiri::HTML(open('http://www.indianrail.gov.in/pnr_Enq.html'))
  	captchaID = doc.css("//input[@id='txtCaptcha']").first["value"]
  	form_action = doc.css("//form[@id='form3']").first["action"]
  	return captchaID, form_action
  end	
  
  def construct_post_params(captchaID, pnrNo)
  	post_params = {}
    post_params["lccp_pnrno1"] = pnrNo
    post_params["lccp_cap_val"] = captchaID
    post_params["lccp_capinp_val"] = captchaID
    post_params["submit"] = "Get+Status"
    data = post_params.map{|k,v| "#{k}=#{v}"}.join('&')
    return data
  end	
  
  def query_railway_server(data, form_action)
  	uri = URI.parse(form_action)
    initheader = {'Referer'=> 'http://www.indianrail.gov.in/pnr_Enq.html', 'Host' =>'www.indianrail.gov.in', 'User-Agent' => 'Fiddler'}
    http = Net::HTTP.new(uri.host,uri.port)
    resp, body = http.post(uri.path, data, initheader)
    return resp.body
  end	


  

end
