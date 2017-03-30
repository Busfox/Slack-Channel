class Tokens < ActiveRecord::Migration
  def change
    create_table :tokens do |t|
      t.string :myshopify_url
      t.string :shopify_token
      t.string :slack_token
      t.string :bot_token
    end
  end
end
