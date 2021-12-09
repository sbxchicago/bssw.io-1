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
    additionals = event.special_additional_dates.map{|date| 
      "<strong>#{date.label.titleize}</strong> " + date.additional_date_values.map{ |adv|
        date_range(adv.date, nil)
      } }.join('; ')

#     ([event.start_at.blank? ? "" : "<strong>Dates</strong> #{date_range(event.start_at, event.end_at)}".html_safe]
# #     + additionals
#     ).delete_if?{|d| d.blank? }.join('<br />').html_safe
  end

  def show_date(date_value)
    date = date_value.additional_date
    if date.label == 'Start Date'
      "#{date_range(date.event.start_at,
                                           date.event.end_at)}".html_safe
    else
      "#{date_range(date_value.date, nil)}".html_safe

    end
  end

  def show_label(date_value)
    date = date_value.additional_date
    date.label unless date.label == 'Start Date'
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
