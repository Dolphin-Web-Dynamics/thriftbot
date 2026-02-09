module Ai
  class PricingAdvisor
    def initialize(item)
      @item = item
    end

    def suggest_prices
      prompt = <<~PROMPT
        Based on this thrift item, suggest resale prices for three tiers.
        Return ONLY valid JSON, no other text.

        Item details:
        - Brand: #{@item.brand&.name || "Unknown"}
        - Type: #{@item.item_type}
        - Condition: #{@item.condition&.humanize}
        - Comp price: #{@item.comp_price ? "$#{@item.comp_price}" : "Unknown"}
        - Retail price: #{@item.retail_price ? "$#{@item.retail_price}" : "Unknown"}
        - Acquisition cost: #{@item.acquisition_cost ? "$#{@item.acquisition_cost}" : "Unknown"}

        Pricing tiers:
        - lower: Fast-moving price for Depop/Vinted/Shopify
        - mid: Standard resale for Poshmark/Grailed/Mercari
        - higher: Maximum value for Ebay

        Return format: {"lower": 25.00, "mid": 35.00, "higher": 45.00}
      PROMPT

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [ { role: "user", content: prompt } ],
          temperature: 0.3,
          max_tokens: 100
        }
      )

      raw = response.dig("choices", 0, "message", "content")&.strip
      JSON.parse(raw)
    rescue JSON::ParserError
      nil
    end

    private

    def client
      @client ||= OpenAI::Client.new(access_token: Rails.application.credentials.dig(:openai, :api_key))
    end
  end
end
