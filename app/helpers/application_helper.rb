# frozen_string_literal: true

# view helpers
module ApplicationHelper


  def listings(author)
    [(author.resource_listing if author.resource_listing != "0 resources"),
     (author.blog_listing if author.blog_listing != "0 blog posts"),
    (author.event_listing if author.event_listing != "0 events")].delete_if{|list| list.nil?}.join(', ')
  end
  
  def search_result_url(result)
    if result.is_a?(SiteItem) 
      site_item_url(result)
    elsif result.is_a?(Author)
      site_items_url(author: result.slug)
    elsif result.is_a?(Fellow)
      fellow_url(result)
    end
  end

  
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
    ([ "<strong>Dates</strong> #{date_range(event.start_at, event.end_at)}".html_safe ] +   
    
      event.additional_dates.map{ |date| 
      "<strong>#{date.label.titleize}</strong> #{date_range(date.start_at, date.end_at)}"}
   ).join('<br />').html_safe
  end

  def show_date(event)
    "<strong>#{event.next_date.first.titleize}</strong> #{date_range(event.next_date[1], event.next_date[2])}".html_safe
  end

  
  def date_range(start_at, end_at)
    start_date = start_at.strftime('%b %e, %Y')
    end_date = end_at
    end_date = end_date.strftime('%b %e, %Y') if end_date

    if start_at == end_at || !end_date
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
