Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Chrome extensions use chrome-extension:// origin
    origins %r{\Achrome-extension://}

    resource "/api/*",
      headers: :any,
      methods: [ :get, :patch, :options ],
      expose: [ "Authorization" ],
      max_age: 3600
  end
end
