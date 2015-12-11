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
  
  template = {
    incident: [],
    kb: []
  }
  # Copying our template to reduce code duplication
  numbers = Hash.new.merge(template)
  query_numbers = Hash.new.merge(template)
  all_items = Hash.new.merge(template)
  items_with_links = Hash.new.merge(template)

  # Encapsulate scanning for relevant strings
  numbers[:incident] = Incident.scan_for_matches(message)
  numbers[:kb] = Knowledge.scan_for_matches(message)


  # TODO: Add comments and log statements
  # maybe keep track of how many times we pull from the cache?
  # also maybe track how many un-supported regex responses we get?
  numbers.each_pair do |table, nums|
    nums.each do |num|
      if item = REDIS.get(num)
        all_items[table] << JSON.parse(item)
      else
        query_numbers[table] << num
      end
    end
  end

  query_numbers.each_pair do |table, nums|
    items_from_sl = []
    case table
    when :incident
      items_from_sl = sl.query(Incident.table, nums)
    when :kb
      items_from_sl = sl.query(Knowledge.table, nums)
    end
    items_from_sl.each do |item|
      all_items[table] << item
      REDIS.set(item['number'], item.to_json)
    end
  end

  all_items.each_pair do |table, nums|
    nums.each do |sl_item|
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
