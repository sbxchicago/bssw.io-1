# frozen_string_literal: true

# controller for the Resource class
class ResourcesController < ApplicationController
  if Rails.env != 'preview'
    http_basic_authenticate_with name: Rails.application.credentials.import['name'],
                                 password: Rails.application.credentials.import['password'], only: ['import']
  end

  def show
    @resource = scoped_resources.find(params[:id])
    redirect_to "/events/#{@resource.slug}" if @resource.is_a?(Event)
    redirect_to "/blog_posts/#{@resource.slug}" if @resource.is_a?(BlogPost)
  end

  def index
    populate_resources
    respond_to do |format|
      format.html
      format.js
      format.rss do
        @resources = scoped_resources.rss
        render layout: false
      end
    end
  end

  def search
    search_string = params[:search_string]
    if search_string.blank?
      @resources = scoped_resources.paginate(page: params[:page], per_page: 25)
    else
      @search_string = search_string
      perform_search(Searchable.prepare_strings(search_string))
    end
    render 'index'
  end

  def authors
    @authors = Author.displayed.order('alphabetized_name ASC, first_name ASC')
    @page = Page.displayed.find_by_name('Contributors')
  end

  private

  def perform_search(search)
    @search = search
    @results = Searchable.perform_search(search, params[:page])
    @resources = @results
  end

  def populate_resources
    set_filters
    @resources = scoped_resources
    @resources = scoped_resources.joins(:siteitems_topics).with_topic(@topic) if @topic
    @resources = scoped_resources.with_category(@category) if @category
    @resources = scoped_resources.with_author(@author) if @author
    @resources = @resources.standard_scope
    paginate
  end

  def paginate
    @resources = if params[:view] == 'all'
                   @resources.paginate(page: 1, per_page: @resources.size)
                 else
                   @resources.paginate(page: params[:page], per_page: 75)
                 end
  end

  def set_filters
    category = params[:category]
    topic = params[:topic]
    author = params[:author]
    @category = Category.displayed.find(category) if category
    @topic = Topic.displayed.find(topic) if topic
    @author = Author.displayed.find(author) if author
  end
end
