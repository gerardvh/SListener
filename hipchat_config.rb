require 'json'
require 'rest-client'
require 'base64'

class Hipchat_helper

  attr_reader :all_config

  @@dev_url = 'https://eba84e50.ngrok.io/api/all'
  @@prod_url = 'https://sl-listener.herokuapp.com/api/all'

  # Pass in optional argument for dev_mode to adjust the url from development to production. 
  # Defaults to dev_mode=true.
  def initialize(dev_mode=true)
    @all_config = {
      name: 'SListener',
      description: 'An add-on that listens for ServiceLink incidents and returns a structured and useful response to HipChat.',
      key: 'com.gerardvh.sl_incident_listener',
      links: {
        homepage: 'https://gerardvh.com',
        self: 'https://eba84e50.ngrok.io/config/all'
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

  # Pass in a block of text and get back a hash full of matches with symbol keys
  # referring to :incident, :kb, :task, and :ritm.
  def scan_for_matches message
    patterns = {
      incident: @@incident_pattern,
      kb: @@kb_pattern,
      task: @@task_pattern,
      ritm: @@ritm_pattern
    }
    # hash to store matches
    matches = {}
    # scan for each pattern and save results in uppercase
    patterns.each do |key,value|
      matches[key] = message.scan(value).uniq.each { |m| m.upcase! }
    end 
    # return resulting hash
    return matches
  end

  # Connection to Umich Service Link by passing in the table to query.
  # Will return a connection object from Rest-client
  def sl_connection table
    user = ENV['SL_USER']
    password = ENV['SL_PASSWORD']
    baseURL = 'https://umichprod.service-now.com/api/now/table/'
    sl_headers = {
      authorization: "Basic #{Base64.strict_encode64("#{user}:#{password}")}",
      accept: 'application/json'
      }
    RestClient::Resource.new baseURL + table, headers: sl_headers
  end

  # Perform the query to Service Link with provided table and query string.
  def query table, query_str
    # TODO: add support for all potential tables
    items = []
    response = JSON.parse sl_connection(table).get params: { sysparm_query: query_str }
    # save the result for each item into an array
    response['result'].each { |item| items << item }
    return items
  end

  # Returns a string of items in a collection separated by '^OR' which is
  # appropriate for the Service Link API.
  def get_query_str sl_numbers
    # TODO: add support for all potential tables
    # chain together multiple searches for one http request
    param_str = sl_numbers.join('^OR')
  end
end
