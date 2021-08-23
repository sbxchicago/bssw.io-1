# frozen_string_literal: true

# view helpers
module ApplicationHelper
  def social_title
    return @post.name if @post
    return @page.name if @page
    return @event.name if @event
    return @resource.name if @resource
  end

  def social_image
    return @post.open_graph_image_tag if @post
    return @event.open_graph_image_tag if @event
    return @page.open_graph_image_tag if @page
    return @resource.open_graph_image_tag if @resource.respond_to?(:open_graph_image_tag)
  end

  def social_description
    return strip_tags(@post.snippet) if @post
    return strip_tags(@page.snippet) if @page
    return strip_tags(@event.snippet) if @event
    return strip_tags(@resource.snippet) if @resource
  end

  def author_list(resource)
    resource.author_list.html_safe
  end

  def author_list_without_links(resource)
    resource.author_list_without_links.html_safe
  end

  def show_dates(event)
    start_date = event.start_at.strftime('%b %e, %Y')
    end_date = event.end_at
    end_date = end_date.strftime('%b %e, %Y') if end_date

    if event.start_at == event.end_at || !end_date
      start_date.html_safe
    else
      "#{start_date}&ndash;#{end_date}".html_safe
    end
  end

  def show_page(path, next_page)
    if path.match(/page/)
      path.gsub(/page.?\d+/, "page=#{next_page}").html_safe
    else
      (path + "?&page=#{next_page}").html_safe
    end
  end
end
