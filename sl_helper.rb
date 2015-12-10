
class Sl_helper
  @@incident_pattern = /[iI][nN][cC]\d{7}\b/
  @@kb_pattern = /[kK][bB]\d{7}\b/
  @@task_pattern = /[tT][aA][sS][kK]\d{7}\b/
  @@ritm_pattern = /[rR][iI][tT][mM]\d{7}\b/

  # Pass in a block of text and get back a hash full of matches with symbol keys
  # referring to :incident, :kb, :task, and :ritm.
  def scan_for_matches message
    p "looking for matches in message: #{message}"
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
      initial_matches = message.scan(value).uniq.each { |m| m.upcase! }
      p "found these matches: #{initial_matches}"
      matches[key] = initial_matches.uniq
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
  def query table, query_array
    # TODO: add support for all potential tables
    p "got to query"
    items = []
    query_str = ""

    case table
    when 'incident', 'kb_knowledge'
      new_query = query_array.map { |q| "number=#{q}" }
      query_str = new_query.join('^OR')
    end

    sl_connection(table).get params: { 
      sysparm_query: query_str, 
      sysparm_limit: 20,
      sysparm_fields: 'number,sys_id,short_description,description,caller_id,text',
      sysparm_display_value: true,
      sysparm_exclude_reference_link: true
    }{ | response, request, result, &block |
      # p request
      case response.code
      when 200
        if result = JSON.parse(response)['result']
          result.each { |item| items << item }
        end
      end
    }
    
    return items
  end
end
