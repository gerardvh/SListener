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
  return Hipchat_helper.all_config
end

post '/api/all' do
  items = api_all_helper(request)
  unless items.empty?
    html_message = erb :hipchat_kb, locals: items
    return Hipchat_helper.return_message(html_message)
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
    Incident.table => [],
    Knowledge.table => []
  }
  # Copying our template to reduce code duplication
  numbers = template.clone
  query_numbers = template.clone
  all_items = template.clone
  items_with_links = template.clone

  # Encapsulate scanning for relevant strings
  numbers[Incident.table] = Incident.scan_for_matches(message)
  numbers[Knowledge.table] = Knowledge.scan_for_matches(message)


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
    items_from_sl = sl.query(table, nums)
    items_from_sl.each do |item|
      all_items[table] << item
      REDIS.set(item['number'], item.to_json)
    end
  end

  all_items.each_pair do |table, sl_items|
    sl_items.each do |item|
      case table
      when Incident.table
        # Maybe I can override item init to take a table parameter and do the logic there?
        p items_with_links
        p "table = #{table}"
        items_with_links[table] << Incident.new(item['number'], Incident.link(item['sys_id']), item['short_description'])
      when Knowledge.table
        items_with_links[table] << Knowledge.new(item['number'], Knowledge.link(item['number']), item['short_description'])
      end
    end
  end

  return items_with_links 
end
