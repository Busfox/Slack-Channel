class SlackAuth < SlackChannel
  set :protection, :except => :frame_options
  def initialize
    Dotenv.load
    @client_id = ENV['SLACK_CLIENT_ID']
    @slacksecret = ENV['SLACK_API_SECRET']
    @redirect_uri = ENV['SLACK_REDIRECT_URI']
    @bot_scope = "bot,chat:write:bot"
    $slacktoken = {}
    $bottoken = {}
    $teamname = ""
    super
  end

  get '/slackinstall' do
    headers({ 'X-Frame-Options' => '' })
    @install_url = "https://slack.com/oauth/authorize?client_id=#{@client_id}&scope=#{@bot_scope}&redirect_uri=#{@redirect_uri}"
    erb :index
  end


  get '/slackauth' do
    code = params[:code]
    puts code
    response = HTTParty.post("https://slack.com/api/oauth.access",
      body: { client_id: @client_id, client_secret: @slacksecret, code: code, redirect_uri: @redirect_uri})

    puts response.code
    puts response

    if (response.code == 200)
      x = Tokens.find_by(myshopify_url: "#{$shop}")
      x.slack_token = response['access_token']
      x.bot_token = response['bot']['bot_access_token']
      x.save
      puts "Access token granted successfully."
    else
      return [500, "No Bueno"]
    end

    redirect '/slackbot'

  end

  get '/slackbot' do


  end

end
