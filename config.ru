require 'sinatra'
require './channel'
require './slackauth'


run SlackChannel
run SlackAuth
