require 'json'

class Hipchat_helper

  attr_reader :all_config

  @@dev_url = 'https://9223f920.ngrok.io/api/all'
  @@prod_url = 'https://sl-listener.herokuapp.com/api/all'

  def initialize(dev_mode=true)
    @all_config = {
      name: 'SListener',
      description: 'An add-on that listens for ServiceLink incidents and returns a structured and useful response to HipChat.',
      key: 'com.gerardvh.sl_incident_listener',
      links: {
        homepage: 'https://gerardvh.com',
        self: 'https://9223f920.ngrok.io/config/all'
      },
      capabilities: {
      hipchatApiConsumer: {
        scopes: [
            'send_notification'
        ]
      },
      webhook: [{
        url: dev_mode ? @@dev_url : @@prod_url,
        pattern: '[incrmtaskbINCRMTASKB]{2,4}\d{7}\b',
        event: 'room_message',
        name: 'sl_all_listener'
        }]
      }
    }
  end
end

class Sl_helper
  @@incident_pattern = /[iI][nN][cC]\d{7}\b/
  @@kb_pattern = /[kK][bB]\d{7}\b/
  @@task_pattern = /[tT][aA][sS][kK]\d{7}\b/
  @@ritm_pattern = /[rR][iI][tT][mM]\d{7}\b/

  def scan_for_matches message
    # hash to store matches
    matches = {}
    # scan for incident #'s and consolidate case
    matches[:incident] = message.scan(@@incident_pattern).each { |m| m.upcase! }
    # scan for KB's and consolidate case
    matches[:kb] = message.scan(@@kb_pattern).each { |m| m.upcase! }
    # scan for tasks and consolidate case
    matches[:task] = message.scan(@@task_pattern).each { |m| m.upcase! }
    # scan for ritms and consolidate case
    matches[:ritm] = message.scan(@@ritm_pattern).each { |m| m.upcase! }
    return matches
  end
end