require 'json'
class Hipchat_helper
  @@Base_url = 'https://service-links.herokuapp.com'
  @@prod_url = "#{@@Base_url}/api/all"
  # Pattern: Maybe start with '/', match 2-4 letters (upper or lower-case), followed by 7 digits that end at the border of a word
  @@All_pattern = '\/?(?:[a-z]|[A-Z]{2,4})\d{7}\b'

  def self.all_config
    {
      name: 'ServiceLinks',
      description: 'An add-on that listens for ServiceLink incidents and returns a structured and useful response to HipChat.',
      key: 'com.gerardvh.sl_incident_listener',
      links: {
        homepage: 'https://gerardvh.com',
        self: "#{@@Base_url}/config/all"
      },
      capabilities: {
      hipchatApiConsumer: {
        scopes: [
          'send_notification'
        ]
      },
      webhook: [{
        url: @@prod_url,
        pattern: @@All_pattern,
        event: 'room_message',
        name: 'sl_all_listener' }]
      }
    }.to_json
  end

  def self.return_message message
    {
      color: "green",
      message: message,
      notify: false,
      message_format: "html" }.to_json
  end
end
