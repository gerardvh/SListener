require 'base64'
require 'rest-client'
require_relative 'sl_items'

class Sl_helper
  @@task_pattern = /[tT][aA][sS][kK]\d{7}\b/
  @@ritm_pattern = /[rR][iI][tT][mM]\d{7}\b/

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
    # p "got to query"
    items = []
    query_str = ""

    case table
    when 'incident', 'kb_knowledge'
      new_query = query_array.map { |q| "number=#{q}" }
      query_str = new_query.join('^OR')
    end

    unless query_str == "" # Don't actually query SL if we don't have any parameters
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
    end
    

    # sl_items = []

    # Make new Sl_items based on which table was queried and return those
    # case table
    # when 'incident'
    #   items.each do |inc|
    #     link = Incident.link(inc['sys_id'])
    #     sl_items << Incident.new(inc['number'], link, inc['short_description'])
    #   end
    # when 'kb_knowledge'
    #   items.each do |kb|
    #     link = Knowledge.link(kb['number'])
    #     sl_items << Knowledge.new(kb['number'], link, kb['short_description'])
    #   end
    # end
    
    # Return either an empty array, or an array of hashes
    return items
  end
end
