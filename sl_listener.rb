require 'sinatra'
require 'tilt/erubis'
require 'json'

require_relative('hipchat_config')
require_relative('sl_helper')
require_relative('sl_items')

get '/config/all' do
  hip = Hipchat_helper.new(dev_mode=false)
  hip.all_config.to_json
end

post '/api/all' do
  items = api_all_helper(request)
  html_message = erb :hipchat_kb, locals: items
  return Hipchat_helper.hipchat_return_message(html_message)
end

def api_all_helper request
  sl = Sl_helper.new
  # rewind in case it was read by something else
  request.body.rewind
  # get what the user said in chat
  message = JSON.parse(request.body.read)['item']['message']['message']
  p "got the message: #{message}"
  # Encapsulate scanning for relevant strings (for flexibility)
  incident_numbers = Incident.scan_for_matches(message)
  kb_numbers = Knowledge.scan_for_matches(message)

  all_items = {}

  unless incident_numbers.empty?
    all_items[:incident] = sl.query(Incident.table, incident_numbers)
  end

  unless kb_numbers.empty?
    all_items[:kb] = sl.query(Knowledge.table, kb_numbers)
  end

  return all_items

  # TODO: handle KB's and DRY out above code

  # Encapsulate packaging response for hipchat
  
  # IDEAS:
  # send all traffic through here since we want to group responses anyway
  # use regex to parse for matches of KB's, Incidents, and Tasks/RITMs
  # add each link to <li> for the response
  
end


# {incident: 'incident',
#     kb: 'kb_knowledge',
#     task: 'sc_task',
#     ritm: 'sc_req_item'}
