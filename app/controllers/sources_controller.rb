class SourcesController < ApplicationController
  def index
    @sources = Source.order(:name)
  end

  def create
    @source = Source.new(name: params[:source][:name])
    if @source.save
      redirect_back fallback_location: sources_path, notice: "Source created."
    else
      redirect_back fallback_location: sources_path, alert: @source.errors.full_messages.join(", ")
    end
  end
end
