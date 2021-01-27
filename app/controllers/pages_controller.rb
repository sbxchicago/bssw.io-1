# frozen_string_literal: true

# display content pages
class PagesController < ApplicationController
  def show
    @page = Page.displayed.find_by_slug(params[:id])
    raise ActionController::RoutingError, 'Not Found' unless @page

    @quote = Quote.displayed.find(Quote.displayed.pluck(:id).sample) unless Quote.displayed.empty? || !(@page.home?)
    @contribute = Contribute.new
    redirect_to action: 'new', controller: 'contacts' if @page.name == 'Contact BSSw'
  end
end
