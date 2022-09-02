# frozen_string_literal: true

# show past and upcoming events
class EventsController < ApplicationController
  def index
    filter_events
    @events = @events.distinct
    page_val = 25
    @total = @events.size
    @last_page = (@events.size.to_f / page_val).ceil
    @current_page = (params[:page] || 1).to_i
    puts "big size #{@events.size}"
    if params[:view] == 'all'
      @events = @events.paginate(page: 1, per_page: @events.size)
      @last_page = @current_page = 1
     else
       per_page = (@current_page) * page_val
       @events = @events.paginate(page: 1, per_page: per_page)
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
