# frozen_string_literal: true

# Events e.g. conferences
class Event < Searchable
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
    dates = if date_node.text.match(/\d{1,2}-\d{1,2}-\d{2,4}/)
              date_node.text.split(':').last.split('- ')
            else
              date_node.text.split(':').last.split('-')
            end

    self.start_at = Chronic.parse(dates.first)
    get_end_date(dates.last)
    date_node.try(:parent).try(:remove)
  end

  def get_end_date(end_text)
    end_text = "#{start_at.strftime('%B')} #{end_text}" unless begin
      Date.parse(end_text)
    rescue StandardError
      false
    end
    self.end_at = Chronic.parse(end_text)
    fix_end_year(end_text)
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
