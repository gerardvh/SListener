require 'sinatra'
require 'thin'
require 'tilt/erubis'
require 'json'

require_relative('hipchat_config')


get '/config/incident' do
  config = {
    name: 'SListener',
    description: 'An add-on that listens for ServiceLink incidents and returns a structured and useful response to HipChat.',
    key: 'com.gerardvh.sl_incident_listener',
    links: {
        homepage: 'https://gerardvh.com',
        self: 'https://sl-listener.herokuapp.com/config/incident'
    },
    capabilities: {
    hipchatApiConsumer: {
        scopes: [
            'send_notification'
        ]
    },
    webhook: [{
        url: 'http://96a4b9ae.ngrok.io/api/incident',
        pattern: '[INCinc]+[0-9]{7}',
        event: 'room_message',
        name: 'incident_listener'
        }]
    }
  }
  JSON.dump(config)
  # config.to_json
end

get '/config/kb' do
  config = {
    name: 'KBot',
    description: 'An add-on that listens for ServiceLink knowledge article numbers and returns a structured and useful response to HipChat.',
    key: 'com.gerardvh.sl_kb_listener',
    links: {
        homepage: 'https://gerardvh.com',
        self: 'https://sl-listener.herokuapp.com/config/kb'
    },
    capabilities: {
    hipchatApiConsumer: {
        scopes: [
            'send_notification'
        ]
    },
    webhook: [{
        url: 'http://96a4b9ae.ngrok.io/api/kb',
        pattern: '[KBkb]+[0-9]{7}',
        event: 'room_message',
        name: 'KBot'
        }]
    }
  }
  JSON.dump(config)
end

get '/config/all' do
  JSON.dump(config :all)
end

post '/api/incident' do
  request.body.rewind
  data = JSON.parse request.body.read
  logger.info "Got this as a request body: #{data}"
  # Think about if I can have all the possibilities in one API
  # and use regex to do control flow. It may be that there are 
  # several different types of data in one big message.
end

post '/api/kb' do
  base_url = "https://umichprod.service-now.com/kb_view.do?sysparm_article="

  request.body.rewind
  @data = JSON.parse request.body.read
  # search data for matching regex responses
  # throw KB #'s at the end of the standard url
  # pass to the response
  logger.info "#{@data['event']}"
  matchesKB = /[KBkb]+[0-9]{7}/.match(@data['item']['message']['message'])
  logger.info "Matches: #{matchesKB}" # TODO: make this match > 1 item

  erb :hipchat_kb, locals: @data
end