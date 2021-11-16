# frozen_string_literal: true

# show past and upcoming events
class EventsController < ApplicationController
  def index
    page = params[:page]
    filter_events
    @dates = AdditionalDateValue.from_events(@events) 

    @dates = if params[:view] == 'all'
               @dates.paginate(page: 1, per_page: @dates.size)
             else
               @dates.paginate(page: page, per_page: 25)
             end

  end

  def show
    @event = scoped_resources.events.find(params[:id])
    @resource = @event
  end

  private

  def filter_events
    author = params[:author]
    events = Event.displayed.published
    if author
      @events = events.with_author(Author.displayed.find(author))
    else
      filter_events_by_time(events)
    end
  end

  def filter_events_by_time(events)
    if params[:past]
      @page = Page.find_by_name('Past Events')
      @events = @past_events = events.past
    else
      @page = Page.find_by_name('Upcoming Events')
      @events = @upcoming_events = events.upcoming
    end
  end
end
