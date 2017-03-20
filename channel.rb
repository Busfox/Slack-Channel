require 'dotenv'
require 'sinatra/base'
require 'shopify_api'
require 'httparty'
require 'pry'

class SlackChannel < Sinatra::Base

  def initialize
    Dotenv.load
    @key = ENV['API_KEY']
    @secret = ENV['API_SECRET']
    @app_url = "drewbie.ngrok.io"
    @tokens = {}
    super
  end

end

GoodieBasket.run! if __FILE__ == $0
