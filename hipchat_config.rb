require 'json'

@dev_switch = true
@dev_url = 'https://a8d04336.ngrok.io/api/all'

def dev?
  # true if in development mode
  @dev_switch
end

def config (table = :all)
  # Expects a symbol to choose a particular config
  # prefers to use :all 
  case table
  when :all
    @all_config.to_json
  when :incident
    @incident_config
  when :kb
    @kb_config
  when :task
    @task_config
  when :ritm
    @ritm_config
  end
end


@all_config = {
  name: 'SListener',
  description: 'An add-on that listens for ServiceLink incidents and returns a structured and useful response to HipChat.',
  key: 'com.gerardvh.sl_incident_listener',
  links: {
    homepage: 'https://gerardvh.com',
    self: 'https://sl-listener.herokuapp.com/config/all'
  },
  capabilities: {
  hipchatApiConsumer: {
    scopes: [
        'send_notification'
    ]
  },
  webhook: [{
    url: @dev_url,
    pattern: '/[incrmtaskb]{2,4}\d{7}\b/ig',
    event: 'room_message',
    name: 'sl_all_listener'
    }]
  }
}



incident_config = {
  name: 'SListener',
  description: 'An add-on that listens for ServiceLink incidents and returns a structured and useful response to HipChat.',
  key: 'com.gerardvh.sl_incident_listener',
  links: {
    homepage: 'https://gerardvh.com',
    self: 'https://sl-listener.herokuapp.com/config/incident'
  },
  capabilities: {
  hipchatApiConsumer: {
    scopes: [
        'send_notification'
    ]
  },
  webhook: [{
    url: 'http://96a4b9ae.ngrok.io/api/incident',
    pattern: '[INCinc]+[0-9]{7}',
    event: 'room_message',
    name: 'incident_listener'
    }]
  }
}

kb_config = {
  name: 'KBot',
  description: 'An add-on that listens for ServiceLink knowledge article numbers and returns a structured and useful response to HipChat.',
  key: 'com.gerardvh.sl_kb_listener',
  links: {
    homepage: 'https://gerardvh.com',
    self: 'https://sl-listener.herokuapp.com/config/kb'
  },
  capabilities: {
  hipchatApiConsumer: {
    scopes: [
      'send_notification'
    ]
  },
  webhook: [{
    url: 'http://96a4b9ae.ngrok.io/api/kb',
    pattern: '[KBkb]+[0-9]{7}',
    event: 'room_message',
    name: 'KBot'
    }]
  }
}

config :all