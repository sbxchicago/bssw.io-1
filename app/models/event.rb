# frozen_string_literal: true

# Events e.g. conferences
class Event < SiteItem
  # validates_uniqueness_of :path

  # has_many :announcements

  # extend FriendlyId
  # friendly_id :slug_candidates, use: %i[finders slugged scoped], scope: :rebuild_id

  def update_from_content(doc, rebuild)
    update_details(doc)
    overview = doc.at("p:contains('Overview')")
    overview&.remove
    super(doc, rebuild)
  end

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
    update_dates(doc.at("li:contains('Date')"))
    doc.at("strong:contains('Description')").try(:remove)
  end

  def update_dates(date_node)
    return unless date_node

    dates = date_node.text.split(':').last.split(' -')

    start_text = dates.first
    end_text = dates.last
    self.start_at = Chronic.parse(start_text)
    self.end_at = Chronic.parse(end_text)

    end_year = end_text.match(/\d{4}/)
    if broken_range? && end_year
      self.start_at = start_at.change(year: end_year[0].to_i)
    elsif broken_range?
      self.start_at = end_at.change(year: end_at.year + 1)
    end

    save
    date_node.try(:parent).try(:remove)
  end
end
