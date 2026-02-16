class Rack::Attack
  # Throttle API requests by IP: 60 requests per minute
  throttle("api/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Stricter limit on auth failures: 5 per minute per IP
  throttle("api/auth-failures/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/") && req.env["rack.attack.match_data"]&.dig(:count).to_i > 3
  end

  # Block requests with no Authorization header hitting the API (bots/scanners)
  throttle("api/no-auth/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/") && req.get_header("HTTP_AUTHORIZATION").blank?
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |req|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "rate_limited", retry_after: req.env["rack.attack.match_data"][:period] }.to_json ] ]
  end
end
