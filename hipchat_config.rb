
def all
  all_config = {
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
      url: 'http://96a4b9ae.ngrok.io/api/all',
      pattern: '/[incrmtaskb]{2,4}\d{7}\b/ig',
      event: 'room_message',
      name: 'sl_all_listener'
      }]
    }
  }
end




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

config = {
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