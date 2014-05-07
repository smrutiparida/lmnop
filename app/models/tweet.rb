class Tweet < ActiveRecord::Base
  attr_accessible :access_token, :access_token_secret, :id, :name, :rank_data, :screen_name
end
