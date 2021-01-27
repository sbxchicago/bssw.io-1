# frozen_string_literal: true

# view helpers
module ApplicationHelper
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
