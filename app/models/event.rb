# frozen_string_literal: true

# Events e.g. conferences
class Event < SiteItem
  def update_from_content(doc, rebuild)
    update_details(doc)
    overview = doc.at("p:contains('Overview')")
    overview&.remove
    super(doc, rebuild)
  end

  scope :past, lambda {
    where(
      'end_at < ?', Date.today
    ).order('start_at DESC')
  }
  scope :upcoming, lambda {
    where('end_at >= ?', Date.today).order('start_at ASC')
  }

  private

  def broken_range?
    end_at && start_at > end_at
  end

  def update_details(doc)
    %w[website location organizers].each do |method|
      node = doc.at("li:contains('#{method.titleize}')")
      send("#{method}=", node.text.split(':').last) if node
    end
    self.website = "http:#{website}" if website
    date_node = doc.at("li:contains('Date')")
    update_dates(date_node) if date_node
    doc.at("strong:contains('Description')").try(:remove)
  end
  
  def update_dates(date_node)
    if date_node.text.match(/\d{1,2}-\d{1,2}-\d{2,4}/)
      dates = date_node.text.split(':').last.split('- ')
    else
      dates = date_node.text.split(':').last.split('-')
    end
    end_text = dates.last
    self.start_at = Chronic.parse(dates.first)
    end_text = "#{start_at.month} #{end_text}" unless (Date.parse(end_text) rescue false)
    self.end_at = Chronic.parse(end_text)
    fix_end_year(end_text)
    date_node.try(:parent).try(:remove)
  end

  def fix_end_year(end_text)
    end_year = end_text.match(/\d{4}/)
    if broken_range? && end_year
      self.start_at = start_at.change(year: end_year[0].to_i)
    elsif broken_range?
      self.start_at = end_at.change(year: end_at.year + 1)
    end
  end
end
