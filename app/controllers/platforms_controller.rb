class PlatformsController < ApplicationController
  def index
    @platforms = Platform.order(:name)
  end
end
