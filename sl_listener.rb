require 'sinatra'
require 'tilt/erubis'
require 'json'

require_relative('hipchat_config')

get '/config/all' do
  hip = Hipchat_helper.new(dev_mode=true)
  hip.all_config.to_json
end

post '/api/all' do
  api_all_helper(request)
end

post '/api/incident' do
  api_all_helper(request)
end

post '/api/kb' do
  api_all_helper(request)
end

def api_all_helper request
  sl = Sl_helper.new
  # rewind in case it was read by something else
  request.body.rewind
  # get what the user said in chat
  message = JSON.parse(request.body.read)['item']['message']['message']
  # Encapsulate scanning for relevant strings (for flexibility)
  # can be accessed with symbols like all_matches[:incident] => array of unique matches
  all_matches = sl.scan_for_matches(message)

  all_items = {}

  {incident: 'incident'}.each do |key, value|
    all_items[key] = sl.query(value, sl.get_query_str(all_matches[key])) 
  end

  return all_items.to_json
  # Encapsulate getting data from SL somehow
  # query_str = sl.get_query_str(all_matches[:incident])
  # incident_ids = sl.query('incident', query_str)

  # query_str = sl.get_query_str(all_matches[:task])
  # task_ids = sl.query('task', query_str)

  # query_str = sl.get_query_str(all_matches[:ritm])
  # ritm_ids = sl.query('ritm', query_str)

  # TODO: handle KB's and DRY out above code

  # Encapsulate packaging response for hipchat

  
  # IDEAS:
  # send all traffic through here since we want to group responses anyway
  # use regex to parse for matches of KB's, Incidents, and Tasks/RITMs
  # add each link to <li> for the response
  
end