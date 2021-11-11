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
    (["<strong>Dates</strong> #{date_range(event.start_at, event.end_at)}".html_safe] +
      event.additional_dates.map do |date|
        "<strong>#{date.label.titleize}</strong> #{date_range(date.start_at, date.end_at)}"
      end
    ).join('<br />').html_safe
  end

  def show_date(event)
    "<strong>#{event.next_date.first.titleize}</strong> #{date_range(event.next_date[1], event.next_date[2])}".html_safe if event.next_date
  end

  def date_range(start_at, end_at)
    return unless start_at
    start_date = start_at.strftime('%b %e, %Y')
    return start_date.html_safe if start_at == end_at || !end_at

    start_date = start_at.strftime('%b %e') if start_at.year == end_at.year
    end_date = if end_at.month == start_at.month
                 end_at.strftime('%e, %Y')
               else
                 end_at.strftime('%b %e, %Y')
               end
    "#{start_date}&ndash;#{end_date}".html_safe
  end

  def show_page(path, next_page)
    if path.match(/page/)
      path.gsub(/page.?\d+/, "page=#{next_page}").html_safe
    else
      (path + "?&page=#{next_page}").html_safe
    end
  end
end
