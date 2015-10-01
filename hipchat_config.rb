require 'json'
require 'rest-client'
require 'base64'

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
    patterns = {
      incident: @@incident_pattern,
      kb: @@kb_pattern,
      task: @@task_pattern,
      ritm: @@ritm_pattern
    }
    # hash to store matches
    matches = {}

    patterns.each do |key,value|
      matches[key] = message.scan(value).uniq.each { |m| m.upcase! }
    end 
    
    # scan for incident #'s and consolidate case
    unique_incidents = message.scan(@@incident_pattern).uniq
    matches[:incident] = unique_incidents.each { |m| m.upcase! }
    # scan for KB's and consolidate case
    unique_kbs = message.scan(@@kb_pattern).uniq
    matches[:kb] = unique_kbs.each { |m| m.upcase! }
    # scan for tasks and consolidate case
    unique_tasks = message.scan(@@task_pattern).uniq
    matches[:task] = unique_tasks.each { |m| m.upcase! }
    # scan for ritms and consolidate case
    unique_ritms = message.scan(@@ritm_pattern).uniq
    matches[:ritm] = unique_ritms.each { |m| m.upcase! }
    # return our consolidated hash of results
    return matches
  end

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

  def query table, query_str
    response = JSON.parse sl_connection(table).get params: { number: query_str }
    response['result'].each { |item| @ids << item['sys_id'] }
    return @ids
  end

  def get_query_str sl_numbers
    # chain together multiple searches for one http request
    param_str = sl_numbers.each { |num| num += '^OR'}
    # remove the last '^OR'
    param_str.chomp!('^OR')
  end

  def rest_request table, sl_numbers
    case table
      # set a certain value for table when we get a symbol argument
    when :incident
      query_sl('incident', param_str)

      # response = JSON.parse sl_connection('incident').get params: { number: param_str }
      # response['result'].each { |incident| puts incident['sys_id'] }
    when :kb
      # add string to base URL as a string for our link
    when :task
      query_sl('task', param_str)

      # response = JSON.parse sl_connection('task').get params: { number: param_str }
      # response['result'].each { |incident| puts incident['sys_id'] }
    when :ritm
      query_sl('ritm', param_str)

      # response = JSON.parse sl_connection('ritm').get params: { number: param_str }
      # response['result'].each { |incident| puts incident['sys_id'] }
    end
    
  end
end

# sl = Sl_helper.new
# sl.rest_request(:incident, "INC0549670")