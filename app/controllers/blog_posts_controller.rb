# frozen_string_literal: true

# display blog
class BlogPostsController < ApplicationController
  def index
    @page = Page.displayed.find_by_name('BSSw Blog')
    author = params[:author]
    @posts = scoped_resources.blog
    if author
      @posts = @posts.with_author(Author.find_by_slug_and_rebuild_id(author, RebuildStatus.first.display_rebuild_id))
    end
    @posts = @posts.paginate(page: params[:page], per_page: 25)
  end

  def show
    blog = scoped_resources.blog
    @post = blog.find(params[:id])
    @resource = @post
    @related_posts = []
    @post.topics.each do |topic|
      @related_posts += blog.get(topic: topic)
    end
    @related_posts = @related_posts.uniq - [@post]
  end
end
