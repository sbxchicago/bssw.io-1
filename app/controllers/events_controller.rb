# frozen_string_literal: true

# show past and upcoming events
class EventsController < ApplicationController
  def index
    filter_events
    @events = if params[:view] == 'all'

                @events.paginate(page: 1, per_page: @events.size)
              elsif params[:page].to_i == 1 || params[:page].blank?
                @events.paginate(page: 1, per_page: 25)
              else
                older = []
                events = @events
                for i in (1..(params[:page].to_i - 1))
                  older = older + events.paginate(page: i, per_page: 25).map(&:id)
                end
                @events.distinct.where('site_items.id NOT IN (?)', older
                             ).paginate(page: 1, per_page: 25)
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
