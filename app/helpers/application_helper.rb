module ApplicationHelper
  include Pagy::Frontend

  def currency(amount)
    return "-" if amount.nil?
    number_to_currency(amount)
  end

  def status_badge(status)
    colors = {
      "drafted" => "bg-gray-100 text-gray-800",
      "listed" => "bg-blue-100 text-blue-800",
      "sold" => "bg-green-100 text-green-800",
      "archived" => "bg-yellow-100 text-yellow-800",
      "donated" => "bg-purple-100 text-purple-800"
    }
    css = colors[status] || "bg-gray-100 text-gray-800"
    tag.span(status.humanize, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{css}")
  end

  def listing_status_badge(status)
    colors = {
      "draft" => "bg-gray-100 text-gray-800",
      "active" => "bg-green-100 text-green-800",
      "paused" => "bg-yellow-100 text-yellow-800",
      "sold" => "bg-blue-100 text-blue-800",
      "delisted" => "bg-red-100 text-red-800"
    }
    css = colors[status] || "bg-gray-100 text-gray-800"
    tag.span(status.humanize, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{css}")
  end
end
