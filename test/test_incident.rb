ENV['RACK_ENV'] = 'test'

$: << '..'
$: << '../lib'

require 'sl_listener'
require 'bacon'
require 'rack/test'

class Bacon::Context
  include Rack::Test::Methods
end

describe 'The SListener App' do

  def app
    Sinatra::Application
  end

  before do
    @empty_message = 'test message'
    @valid_message = 'INC0603557, INC0598908, KB0018959 INC0603557 TASK0603557 RITM0603557'
    @test_hipchat_body = {
      item: {
        message: {
          message: "This is a test message: #{@valid_message}"
        }
      }
    }.to_json
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
          matches = Incident.scan_for_matches(@valid_message)
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
          Knowledge.scan_for_matches(@valid_message).should.not.be.empty
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
        post '/api/all', body: @test_hipchat_body
        last_response.should.be.ok
      end
      
    end

    describe '.separate_cached_items' do
      it "works with no input" do
        separate_cached_items().should.not.equal nil
        separate_cached_items().should.not.be.empty
        separate_cached_items().should.equal [template, template]
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


