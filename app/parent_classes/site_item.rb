# frozen_string_literal: true

# resources, events, and blog posts

class SiteItem < SearchResult


  require 'csv'
  #include Searchable

#  self.table_name = 'site_items'

  def rss_date
    super || published_at
  end

  def categories
    topics.map(&:category).uniq
  end

  def self.clean
    items = where(name: nil)
    items.each(&:delete)
    Fellow.displayed.each(&:set_search_text)
    displayed.each do |si|
      si.set_search_text
      si.refresh_topic_list
      si.refresh_author_list
    end
  end

  def set_search_text
    text = ActionController::Base.helpers.strip_tags(
      " #{content.to_s.gsub('"', '')} #{try(:author_list)} #{name} #{try(:description)} #{try(:location)} #{try(:organizers)} ".downcase.gsub(/\s+/, " ")
    )
    #    puts text
    update(search_text: text)
    #    save
  end
end
