class GenerateAiContentJob < ApplicationJob
  queue_as :default

  def perform(item_id)
    item = Item.find(item_id)
    generator = Ai::DescriptionGenerator.new(item)
    results = generator.generate_all

    results.each do |field, value|
      next unless value.present?

      item.update_column(field, value)
      item.ai_generations.create!(
        field_name: field.to_s,
        result: value,
        model_used: "gpt-4o-mini"
      )
    end

    item.reload
    broadcast_content(item)
    Rails.logger.info "AI content generated for Item ##{item.id} (#{item.sku})"
  rescue OpenAI::Error => e
    Rails.logger.error "OpenAI API error for Item ##{item_id}: #{e.message}"
    broadcast_error(item_id)
    raise
  end

  private

  def broadcast_content(item)
    Turbo::StreamsChannel.broadcast_replace_to(
      item, "ai_content",
      target: "ai_content",
      partial: "items/ai_content",
      locals: { item: item }
    )
  end

  def broadcast_error(item_id)
    item = Item.find_by(id: item_id)
    return unless item

    Turbo::StreamsChannel.broadcast_replace_to(
      item, "ai_content",
      target: "ai_content",
      html: <<~HTML
        <div id="ai_content" class="bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">AI Generated Content</h2>
          <p class="text-red-500 text-sm">Failed to generate AI content. Please try again.</p>
        </div>
      HTML
    )
  end
end
