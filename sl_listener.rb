# Add ./lib to the load-path
$: << "./lib"

require 'sinatra'
require 'tilt/erubis'
require 'json'
require 'redis'
require 'uri'
# From ./lib
require('hipchat_config')
require('sl_helper')
require('sl_items')

#### Setup REDIS ####
# Use the ENV var with our redis url by not including any arguments.
$redis = Redis.new

get '/config/all' do
  return Hipchat_helper.all_config
end

post '/api/all' do
  # Increment a count of how many times this API is accessed
  $redis.incr('api:all:attempts')
  # rewind in case it was read by something else
  request.body.rewind
  # get what the user said in chat
  begin
    message = JSON.parse(request.body.read)['item']['message']['message']
  rescue Exception => e
    # Return early if we can't parse the JSON from Hipchat
    $redis.incr('api:failure:message_parse')
    return
  end
  
  # Copying our template to reduce code duplication
  # The template method should return a fresh hash with service link table-names
  # as the keys and empty arrays as values.
  numbers = template()

  tasks = Task.scan_for_matches(message)
  unless tasks.empty?
    tasks.each do |task_number|
      # FIXME: "WRONGTYPE" error
      $redis.sadd('api:unsupported:task', task_number)
    end
  end

  requests = Request.scan_for_matches(message)
  unless requests.empty?
    requests.each do |req_number|
      # FIXME: "WRONGTYPE" error
      $redis.sadd('api:unsupported:request', req_number)
    end
  end

  numbers[Incident.table] = Incident.scan_for_matches(message)
  numbers[Knowledge.table] = Knowledge.scan_for_matches(message)

  if numbers[Incident.table].empty? && numbers[Knowledge.table].empty?
    return # Early return if we have no supported items to parse
  end

  cached_items, items_to_query = separate_cached_items(numbers)
  all_items = combine_cache_and_query(cached_items, items_to_query)
  items_with_links = add_links(all_items)

  items_with_links.values.each do |array|
    array.each { $redis.incr('api:all:items_returned') }
  end

  html_message = erb :hipchat_kb, locals: items_with_links
  return Hipchat_helper.return_message(html_message)
end

def template
  # This should return a hash with all the supported SL Tables as keys, and empty arrays as values
  return {
    Incident.table => [],
    Knowledge.table => []
  }
end

def separate_cached_items numbers=template(), cached_items=template(), items_to_query=template()
  numbers.each_pair do |table, nums|
    nums.each do |num|
      if item = $redis.get("#{table}:#{item['num']}")
        cached_items[table] << JSON.parse(item)
      else
        items_to_query[table] << num
      end
    end
  end
  return cached_items, items_to_query
end

def combine_cache_and_query cached_items=template(), items_to_query=template()
  sl = Sl_helper.new # Create a helper for querying Service Link
  items_to_query.each_pair do |table, nums|
    items_from_sl = sl.query(table, nums)
    items_from_sl.each do |item|
      cached_items[table] << item
      # Set our cache for queried items with keys like "incident:INC098219"
      $redis.set("#{table}:#{item['number']}", item.to_json)
    end
  end
  return cached_items # Which now also has the newly queried items as well
end

def add_links items
  items_with_links = template()
  items.each_pair do |table, sl_items|
    sl_items.each do |item|
      case table
      when Incident.table
        items_with_links[table] << Incident.new(item['number'], Incident.link(item['sys_id']), item['short_description'])
      when Knowledge.table
        items_with_links[table] << Knowledge.new(item['number'], Knowledge.link(item['number']), item['short_description'])
      end
    end
  end
  return items_with_links
end