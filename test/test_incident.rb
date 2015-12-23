ENV['RACK_ENV'] = 'test'

$: << '..'
$: << '../lib'

require 'sl_listener'
require 'bacon'
require 'rack/test'
require 'json'

class Bacon::Context
  include Rack::Test::Methods
end

describe 'The SListener App' do

  def app
    Sinatra::Application
  end

  def test_hipchat_body message=""
    {"event"=>"room_message", "item"=>{"message"=>{"date"=>"2015-12-23T20:28:02.856386+00:00", "from"=>{"id"=>2153022, "links"=>{"self"=>"https://api.hipchat.com/v2/user/2153022"}, "mention_name"=>"GerardVanHalsema", "name"=>"Gerard Van Halsema", "version"=>"00000000"}, "id"=>"cfe3f669-0531-4e58-aaa4-4ec30d47fa78", "mentions"=>[], "message"=>"#{message}", "type"=>"message"}, "room"=>{"id"=>2248879, "is_archived"=>false, "links"=>{"participants"=>"https://api.hipchat.com/v2/room/2248879/participant", "self"=>"https://api.hipchat.com/v2/room/2248879", "webhooks"=>"https://api.hipchat.com/v2/room/2248879/webhook"}, "name"=>"slistener2.0", "privacy"=>"public", "version"=>"9GEMO4QZ"}}, "oauth_client_id"=>"aa9e123e-4814-422f-9040-44e919957319", "webhook_id"=>3321968}.to_json
  end

  before do
    @empty_message = 'test message'
    @message_with_each_item = 'INC0603557, INC0598908, KB0018959 INC0603557 TASK0603557 RITM0603557'
  end

  describe 'Configuration' do
    it 'responds to get requests' do
      get '/config/all'
      last_response.should.be.ok
    end

    it "has the expected body" do
      get '/config/all'
      last_response.body.should.equal Hipchat_helper.all_config
    end
  end

  describe SL_item do
    describe Incident do
      describe '.scan_for_matches' do
        it 'finds valid incident numbers' do
          matches = Incident.scan_for_matches(@message_with_each_item)
          # matches.should.not.be.empty
          matches.should.equal ['INC0603557', 'INC0598908']
        end

        it "doesn't get false positives" do
          empty_matches = Incident.scan_for_matches(@empty_message)
          empty_matches.should.be.empty
        end
      end
    end

    describe Knowledge do
      describe '.scan_for_matches' do
        it 'finds valid knowledge numbers' do
          Knowledge.scan_for_matches(@message_with_each_item).should.not.be.empty
        end

        it "doesn't get false positives" do
          Knowledge.scan_for_matches(@empty_message).should.be.empty
        end
      end 
    end

    describe Task do
      
    end

    describe Request do
      
    end
  end

  describe 'API' do
    describe 'ALL' do
      it "can respond to hipchat" do
        post '/api/all', test_hipchat_body(@message_with_each_item)
        last_response.should.be.ok
        last_response.body.should.match Incident.pattern
        last_response.body.should.match Knowledge.pattern
        last_response.body.should.not.match Task.pattern
        last_response.body.should.not.match Request.pattern
      end

      it "doesn't respond when the item is unsupported" do
        post '/api/all', test_hipchat_body("TASK0128982")
        last_response.should.not.be.ok
        last_response.status.should.equal 404
      end

      it "gives an error when it gets malformed JSON" do
        post '/api/all', ""
        last_response.should.not.be.ok
        last_response.status.should.equal 500
      end
      
    end

    describe '.separate_cached_items' do
      it "works with no input" do
        separate_cached_items().should.not.equal nil
        separate_cached_items().should.not.be.empty
        separate_cached_items().should.equal [template, template]
      end

      it "returns items in the cache" do
        numbers = template
        # Assuming these are in the cache at this point.
        numbers[Incident.table] = ['INC0603557', 'INC0598908']
        cached_items, items_to_query = separate_cached_items(numbers)
        cached_items.should.not.equal nil
        cached_items[Incident.table].should.not.be.empty
      end

      it "doesn't return items that are not in the cache" do
        numbers = template
        # Assuming these are in the cache at this point.
        numbers[Incident.table] = ['INC0000000']
        cached_items, items_to_query = separate_cached_items(numbers)
        cached_items.should.not.equal nil
        cached_items[Incident.table].should.be.empty
      end
    end

    describe '.combine_cache_and_query' do
      it "works with no input" do
        combine_cache_and_query().should.not.equal nil
        combine_cache_and_query().should.not.be.empty
        combine_cache_and_query().should.equal template
      end

      it "can query service link for incidents" do
        query = template
        query[Incident.table] = ['INC0598908']
        items = combine_cache_and_query(template, query)
        items.should.not.equal nil
        items[Incident.table].should.not.be.empty
        items[Incident.table][0]['number'].should.equal 'INC0598908'
      end

      it "can query service link for knowledge documents" do
        query = template
        query[Knowledge.table] = ['KB0018959']
        items = combine_cache_and_query(template, query)
        items.should.not.equal nil
        items[Knowledge.table].should.not.be.empty
        items[Knowledge.table][0]['number'].should.equal 'KB0018959'
      end
    end
  end
end


