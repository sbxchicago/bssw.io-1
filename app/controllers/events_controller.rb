# frozen_string_literal: true

# show past and upcoming events
class EventsController < ApplicationController
  def index
    filter_events
    @events = @events.distinct
    puts "---------"
    puts "page: #{params[:page]}"
    if params[:view] == 'all'

      @events =                @events.paginate(page: 1, per_page: @events.size)
    elsif params[:page].to_i == 1 || params[:page].blank?
      @events =            @events.paginate(page: 1, per_page: 25)
    else
      older = @events.paginate(page: 1, per_page: 25 * params[:page].to_i).map(&:id)
      puts "older: #{older.size} "
      @events = @events.where('site_items.id NOT IN (?)', older
                             ).paginate(page: 1, per_page: 25)
    end
    puts "size: #{@events.size}"

    puts "intersection #{(@events.map(&:id) & older).size}" if older 
    puts "first #{@events.first.id}"

    puts "------"
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
