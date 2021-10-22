# frozen_string_literal: true

# Events e.g. conferences
class Event < Searchable

  self.table_name = 'site_items'
  has_many :additional_dates
  
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

  
  private


  def update_details(doc)
    %w[website location organizers].each do |method|
      node = doc.at("li:contains('#{method.titleize}')")
      send("#{method}=", node.text.split(':').last) if node
    end
    self.website = "http:#{website}" if website
    date_nodes = doc.css("li:contains('Date')")  
    update_dates(date_nodes) if date_nodes
    doc.at("strong:contains('Description')").try(:remove)
  end

  # def date_array
  #   [["Start Date", self.start_at], ["End Date", self.end_at]] + self.additional_dates.map{|d| [d.label, d.start_at]}
  # end
  
  def update_dates(date_nodes)
    date_nodes.each do |date_node|
      text = date_node.text
      if text.match(/^Date/)
        dates = if text.match(/\d{1,2}-\d{1,2}-\d{2,4}/)
                  text.split(':').last.split('- ')
                else
                  text.split(':').last.split('-')
                end

        self.start_at = Chronic.parse(dates.first).try(:to_date)
        get_end_date(dates.last)
      else
        dates = if text.match(/\d{1,2}-\d{1,2}-\d{2,4}/)
                  text.split(':').last.split('- ')
                else
                  text.split(':').last.split('-')
                end
        label = text.split(':').first
        date = AdditionalDate.create(label: label, event: self)
        date.start_at = Chronic.parse(dates.first).try(:to_date)
        date.end_at = Chronic.parse(dates.last).try(:to_date)
      end
    date_node.try(:remove)
    end
    self.additional_dates.each{|d| puts d.inspect }
  end

  def get_end_date(end_text)
    end_text = "#{start_at.strftime('%B')} #{end_text}" unless begin
      Date.parse(end_text)
    rescue StandardError
      false
    end
    self.end_at = Chronic.parse(end_text).try(:to_date)
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
