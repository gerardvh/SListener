require 'json'
require 'rest-client'
require 'base64'

class Hipchat_helper

  attr_reader :all_config

  @@dev_url = 'https://eba84e50.ngrok.io/api/all'
  @@prod_url = 'https://sleepy-badlands-1684.herokuapp.com/api/all'
  # Pattern: Maybe start with '/', match 2-4 letters (upper or lower-case), followed by 7 digits that end at the border of a word
  @@all_pattern = '\/?(?:[a-z]|[A-Z]{2,4}\d{7}\b'

  # Pass in optional argument for dev_mode to adjust the url from development to production. 
  # Defaults to dev_mode=true.
  def initialize(dev_mode=true)
    @all_config = {
      name: 'SListener',
      description: 'An add-on that listens for ServiceLink incidents and returns a structured and useful response to HipChat.',
      key: 'com.gerardvh.sl_incident_listener',
      links: {
        homepage: 'https://gerardvh.com',
        self: 'https://sleepy-badlands-1684.herokuapp.com/config/all'
      },
      capabilities: {
      hipchatApiConsumer: {
        scopes: [
            'send_notification'
        ]
      },
      webhook: [{
        url: dev_mode ? @@dev_url : @@prod_url,
        pattern: @@all_pattern,
        event: 'room_message',
        name: 'sl_all_listener'
        }]
      }
    }
  end

  def self.hipchat_return_message message
    {
      color: "green",
      message: message,
      notify: false,
      message_format: "html"
    }.to_json
  end
end
