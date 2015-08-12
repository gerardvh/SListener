require 'sinatra'
require 'json'

get '/config/incident' do
  config = {
    name: "SListener",
    description: "An add-on that listens for ServiceLink incidents and returns a structured and useful response to HipChat.",
    key: "com.gerardvh.sl_incident_listener",
    links: {
        "homepage": "https://gerardvh.com",
        "self": "https://sl-listener.herokuapp.com/config/incident"
    },
    capabilities: {
    hipchatApiConsumer: {
        scopes: [
            "send_notification"
        ]
    },
    webhook: [{
        url: "https://sl-listener.herokuapp.com/api/incident/",
        pattern: "[INCinc]+[0-9]{7}",
        event: "room_message",
        name: "incident_listener"
        }]
    }
  }
  JSON.dump(config)
end

get '/config/kb' do
  config = {
    name: "SListener",
    description: "An add-on that listens for ServiceLink incidents and returns a structured and useful response to HipChat.",
    key: "com.gerardvh.sl_kb_listener",
    links: {
        "homepage": "https://gerardvh.com",
        "self": "https://sl-listener.herokuapp.com/config/kb"
    },
    capabilities: {
    hipchatApiConsumer: {
        scopes: [
            "send_notification"
        ]
    },
    webhook: [{
        url: "https://sl-listener.herokuapp.com/api/kb/",
        pattern: "[INCinc]+[0-9]{7}",
        event: "room_message",
        name: "kb_listener"
        }]
    }
  }
  JSON.dump(config)
end

post "/api/incident" do
  request.body.rewind
  data = JSON.parse request.body.read
  logger.info "Got this as a request body: #{data}"
end

post "/api/kb" do
  request.body.rewind
  data = JSON.parse request.body.read
  logger.info "Got this as a request body: #{data}"
end