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
    self.start_at = Chronic.parse(dates.first)
    self.end_at = Chronic.parse(dates.last)
    self.end_at = self.end_at.change(year: self.start_at.year) if end_at && (start_at > end_at)
    self.end_at = self.end_at.change(year: self.start_at.year + 1) if end_at && (start_at > end_at)
    self.save
    date_node.try(:parent).try(:remove)
  end
end
