require 'dotenv'
require 'sinatra/base'
require 'shopify_api'
require 'httparty'
require 'pry'
require 'json'
require 'mysql2'
require 'sinatra/activerecord'


class SlackChannel < Sinatra::Base
set :protection, :except => :frame_options
set :database, {adapter: "mysql2", database: "development.sql"}
register Sinatra::ActiveRecordExtension

  class Tokens < ActiveRecord::Base
  end


  def initialize
    Dotenv.load
    $key = ENV['API_KEY']
    @secret = ENV['API_SECRET']
    $app_url = "busfox.ngrok.io"
    @tokens = {}
    super
  end

  def verify_request
    hmac = params[:hmac]
    query = params.reject{|k,_| k == 'hmac'}
    message = Rack::Utils.build_query(query)
    digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @secret, message)

    puts "hmac: #{hmac}"
    puts "digest: #{digest}"

    if not (hmac == digest)
      return [401, "Authorization failed!"]
    else
      puts "hmac matches digest"
    end

  end

  get '/app_url' do

    $shop = params[:shop]

    if Tokens.find_by(myshopify_url: "#{$shop}")

    else
      x = Tokens.new
      x.myshopify_url = $shop
      x.save
    end

		scopes = "read_product_listings,write_checkouts"

		install_url = "https://#{$shop}/admin/oauth/authorize?client_id=#{$key}&scope=#{scopes}&redirect_uri=https://#{$app_url}/auth"

		redirect install_url
  end

  get '/auth' do

		code = params[:code]
		verify_request

		response = HTTParty.post("https://#{$shop}/admin/oauth/access_token",
			body: { client_id: $key, client_secret: @secret, code: code})

		puts response.code
		puts response

		if (response.code == 200)
			x = Tokens.find_by(myshopify_url: "#{$shop}")
      x.shopify_token = response['access_token']
      x.save
		else
			return [500, "No Bueno"]
		end

		redirect '/slackinstall'

	end

  post '/test' do
    request.body.rewind
    data = Rack::Utils.parse_nested_query(request.body.read)
    channel = data['channel_name']

    session = ShopifyAPI::Session.new($shop, Tokens.find_by(myshopify_url: "#{$shop}").shopify_token)
    ShopifyAPI::Base.activate_session(session)

    if data['text'] == 'list products'
      products = ShopifyAPI::ProductListing.find(:all, params: { application_id: 1582267 })
      puts products.first
      response = HTTParty.post("https://slack.com/api/chat.postMessage",
        body: {
                token: Tokens.find_by(myshopify_url: "#{$shop}").slack_token,
                channel: "#{channel}",
                text: "#{products}"
              })
      puts response
      puts response.code
      puts "-------------------------------"
      puts response.body
      json = JSON.parse(response.body)
      puts "-------------------------------"
      puts json
    end
  end

end

SlackChannel.run! if __FILE__ == $0
