module Ai
  class DescriptionGenerator
    def initialize(item)
      @item = item
    end

    def generate_all
      results = {}
      results[:chatgpt_description] = generate_description
      results[:shopify_title] = generate_shopify_title
      results[:unified_description] = generate_unified_description(results[:chatgpt_description])
      results
    end

    private

    def client
      @client ||= OpenAI::Client.new(access_token: Rails.application.credentials.dig(:openai, :api_key))
    end

    def chat(prompt, max_tokens: 500)
      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [ { role: "user", content: prompt } ],
          temperature: 0.7,
          max_tokens: max_tokens
        }
      )
      response.dig("choices", 0, "message", "content")&.strip
    end

    def generate_description
      prompt = <<~PROMPT
        Generate a compelling resale listing description for this thrift item:
        - Brand: #{@item.brand&.name || "Unknown"}
        - Category: #{[ @item.category&.name, @item.subcategory&.name ].compact.join(" / ")}
        - Type: #{@item.item_type}
        - Size: #{@item.size}
        - Colors: #{@item.colors}
        - Materials: #{@item.materials}
        - Condition: #{@item.condition&.humanize}
        - Imperfections: #{@item.imperfections.presence || "None"}
        - Model: #{@item.product_model}
        - Gender: #{@item.target_gender&.humanize}

        Write a concise, keyword-rich description suitable for resale platforms like Depop, Poshmark, and Grailed.
        Include relevant style details. Keep it under 200 words. Do not use hashtags.
      PROMPT
      chat(prompt)
    end

    def generate_shopify_title
      prompt = <<~PROMPT
        Generate a Shopify product title for this thrift item:
        - Brand: #{@item.brand&.name || "Unknown"}
        - Type: #{@item.item_type}
        - Colors: #{@item.colors}
        - Size: #{@item.size}
        - Model: #{@item.product_model}
        - Condition: #{@item.condition&.humanize}

        The title should be SEO-friendly, include the brand name, and be under 70 characters.
        Return only the title, nothing else.
      PROMPT
      chat(prompt, max_tokens: 100)
    end

    def generate_unified_description(description)
      prompt = <<~PROMPT
        Create a unified product description combining all details for this thrift item.
        Use this base description: #{description}

        Additional details:
        - Brand: #{@item.brand&.name}
        - Retail Price: #{@item.retail_price ? "$#{@item.retail_price}" : "Unknown"}
        - Comp Price: #{@item.comp_price ? "$#{@item.comp_price}" : "Unknown"}

        Format it as a clean, professional listing description with sections for:
        1. A brief intro highlighting the brand and key features
        2. Details (size, color, material, condition)
        3. A note about the value (compared to retail if available)

        Keep it under 250 words.
      PROMPT
      chat(prompt)
    end
  end
end
