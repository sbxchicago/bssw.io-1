# frozen_string_literal: true

# show past and upcoming events
class EventsController < ApplicationController
  def index
    filter_events
    @events = @events.distinct
    page_val = 25
    @last_page = (@events.size / page_val)
    @current_page = (params[:page] || 1).to_i
    puts "big size #{@events.size}"
    if params[:view] == 'all'
      @events = @events.paginate(page: 1, per_page: @events.size)
      @last_page = @current_page = 1
    else
      per_page = (@current_page) * page_val
      if @current_page == 1
        @events = @events.paginate(page: 1, per_page: page_val)
      else
      #  older = @events.paginate(page: 1, per_page: per_page - page_val)
#        puts "older #{older.count}"
        #        @events = @events.where('site_items.id NOT IN (?)', older.map(&:id)).paginate(page: 1, per_page: per_page)
        puts "per page #{per_page}"
        @events = @events.paginate(page: 1, per_page: per_page)
        puts "blank #{@events.where(id: nil).size}"
        puts "size #{@events.size}"
        puts "size #{@events.map(&:class).size}"
        puts "size #{@events.map(&:id).size}"
        @events.first(10).each { |e| puts e.name }
      end
#      if per_page == 0
      puts "current #{@current_page}"
      puts "last #{@last_page}"
#      puts "older #{(older).map(&:id)}"
#      end
    end
 #   puts "intersection #{(older & @events).size}" if older
    puts "size #{@events.map(&:id).size}"
    puts "-------"
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
