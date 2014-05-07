class CreateTweets < ActiveRecord::Migration
  def change
    create_table :tweets do |t|
      t.string :name
      t.string :id
      t.string :screen_name
      t.text :access_token
      t.text :access_token_secret
      t.text :rank_data

      t.timestamps
    end
  end
end
