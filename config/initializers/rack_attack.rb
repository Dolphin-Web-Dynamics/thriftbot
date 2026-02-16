class Rack::Attack
  # Throttle API requests by IP: 60 requests per minute
  throttle("api/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Stricter limit on auth failures: 5 per minute per IP
  # Uses a cache counter incremented by the application when returning 401/403
  throttle("api/auth-failures/ip", limit: 5, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      count = Rack::Attack.cache.store.read("rack::attack:auth-failures:#{req.ip}") || 0
      req.ip if count.to_i > 0
    end
  end

  # Block requests with no Authorization header hitting the API (bots/scanners)
  # Excludes OPTIONS requests (CORS preflight) which never carry Authorization
  throttle("api/no-auth/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/") &&
              req.request_method != "OPTIONS" &&
              req.get_header("HTTP_AUTHORIZATION").blank?
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |req|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "rate_limited", retry_after: req.env["rack.attack.match_data"][:period] }.to_json ] ]
  end
end

# Track auth failures from app responses and increment Rack::Attack cache counter
ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  if [ 401, 403 ].include?(event.payload[:status]) && event.payload[:path]&.start_with?("/api/")
    ip = event.payload[:request]&.remote_ip
    if ip.present?
      cache_key = "rack::attack:auth-failures:#{ip}"
      store = Rack::Attack.cache.store
      current = store.read(cache_key).to_i
      store.write(cache_key, current + 1, expires_in: 1.minute)
    end
  end
end
