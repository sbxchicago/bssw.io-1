# frozen_string_literal: true

# show past and upcoming events
class EventsController < ApplicationController
  def index
    filter_events
    @events = if params[:view] == 'all'
                @events.paginate(page: 1, per_page: @events.size)
              else
                @events.paginate(page: params[:page] || 1, per_page: 25)
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
    puts @events.map(&:id)
    puts 'distinct'
    @events = @events.distinct
    puts @events.map(&:id)
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
