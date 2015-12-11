require 'sinatra'
require 'tilt/erubis'
require 'json'
require 'redis'
require 'uri'

require_relative('hipchat_config')
require_relative('sl_helper')
require_relative('sl_items')

#### Setup REDIS ####
# Use the ENV var with our redis url by not including any arguments.
REDIS = Redis.new

get '/config/all' do
  hip = Hipchat_helper.new(dev_mode=false)
  hip.all_config.to_json
end

post '/api/all' do
  items = api_all_helper(request)
  unless items.empty?
    html_message = erb :hipchat_kb, locals: items
    return Hipchat_helper.hipchat_return_message(html_message)
  end
end

def api_all_helper request
  sl = Sl_helper.new
  # rewind in case it was read by something else
  request.body.rewind
  # get what the user said in chat
  begin
    message = JSON.parse(request.body.read)['item']['message']['message']
  rescue Exception => e
    # Return early if we can't parse the JSON from Hipchat
    return {}
  end
  
  # Encapsulate scanning for relevant strings
  incident_numbers = Incident.scan_for_matches(message)
  kb_numbers = Knowledge.scan_for_matches(message)

  all_items = {
    incident: [],
    kb: []
  }

  inc_to_query = []
  kb_to_query = []

  incident_numbers.each do |inc|
    if incident = REDIS.get(inc) # Check if it is saved in our db
      # Redis stores all items as a string, so we have it serialized as json
      all_items[:incident] << JSON.parse(incident)
    else
      # If we don't have it in the DB, get ready to query SL
      inc_to_query << inc
    end
  end

  kb_numbers.each do |kb_number|
    if kb = REDIS.get(kb_number) # Check if exists in db
      all_items[:kb] << JSON.parse(kb)
    else
      kb_to_query << kb_number
    end
  end

  unless inc_to_query.empty?
    incs_from_sl = sl.query(Incident.table, inc_to_query)
    unless incs_from_sl.empty? # Make sure we got a response from SL
      incs_from_sl.each do |inc|
        # Add to our active hash
        all_items[:incident] << inc
        # Add to redis store
        REDIS.set(inc['number'], inc.to_json)
      end
    end
  end

  unless kb_to_query.empty?
    kbs_from_sl = sl.query(Knowledge.table, kb_to_query)
    unless kbs_from_sl.empty? # Make sure we got a response from SL
      kbs_from_sl.each do |kb|
        # Add to our active hash
        all_items[:kb] << kb
        # Add to redis store
        REDIS.set(kb['number'], kb.to_json)
      end
    end
  end

  items_with_links = {
    incident: [],
    kb: []
  }

  # all_items[:incident].each do |inc|
  #   # p inc
  #   link = Incident.link(inc['sys_id'])
  #   items_with_links[:incident] << Incident.new(inc['number'], link, inc['short_description'])
  # end

  # all_items[:kb].each do |kb|
  #   link = Knowledge.link(kb['number'])
  #   items_with_links[:kb] << Knowledge.new(kb['number'], link, kb['short_description'])
  # end

  all_items.each_key do |table|
    all_items[table].each do |sl_item|
      case table
      when :incident
        items_with_links[table] << Incident.new(sl_item['number'], Incident.link(sl_item['sys_id']), sl_item['short_description'])
      when :kb
        items_with_links[table] << Knowledge.new(sl_item['number'], Knowledge.link(sl_item['number']), sl_item['short_description'])
      end
    end
  end

  return items_with_links 
end


# {incident: 'incident',
#     kb: 'kb_knowledge',
#     task: 'sc_task',
#     ritm: 'sc_req_item'}
