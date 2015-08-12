require 'sinatra'
require 'tilt/erubis'
require 'json'

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

post '/api/incident' do
  request.body.rewind
  data = JSON.parse request.body.read
  logger.info "Got this as a request body: #{data}"
end

post '/api/kb' do
  request.body.rewind
  @data = JSON.parse request.body.read
  # search data for matching regex responses
  # throw KB #'s at the end of the standard url
  # pass to the response
  logger.info "Got this as a request body: #{@data}"
  
  erb :hipchat_kb, locals: @data
end