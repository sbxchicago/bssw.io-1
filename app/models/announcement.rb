# frozen_string_literal: true

# Announcements display on homepage
class Announcement < GithubImport
  self.table_name = 'announcements'

  scope :for_today, lambda {
                      where('start_date <= ? and end_date >= ?', Date.today, Date.today)
                    }

  def self.import(content, rebuild_id)
    doc = GithubImport.parse_html_from(content)
    doc.css("p:contains('Announcement')").each do |elem|
      next if elem.next_element.blank? || elem.next_element.text.blank?

      Announcement.create_from(elem.next_element, rebuild_id)
    end
  end

  def self.create_from(elem, rebuild_id)
    announcement = Announcement.create(rebuild_id: rebuild_id)
    link = elem.css('a')
    announcement.path = link.attr('href').content
    announcement.text = link.text
    link.remove
    elem.css('li').each do |el|
      announcement.update_dates(el)
    end
    announcement.save
    announcement
  end

  def site_item
    SiteItem.find_by(path: File.basename(path))
  end

  def update_dates(item)
    text = item.text
    return if text.blank?

    dates = text.split(':').last.split('-')
    date = Chronic.parse(dates.last)
    update(
      start_date: Chronic.parse(dates.first),
      end_date: date
    )
    return if date && date > Date.today
  end
end
