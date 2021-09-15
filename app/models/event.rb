# frozen_string_literal: true

# Events e.g. conferences
class Event < Dateable


  has_many :additional_dates
  
  def update_from_content(doc, rebuild)
    update_details(doc)
    overview = doc.at("p:contains('Overview')")
    overview&.remove
    super(doc, rebuild)
  end

  scope :past, lambda {
    joins(:additional_dates).where(
                   'additional_dates.end_at < ?', Date.today
                   ).order('start_at DESC')
  }
  scope :upcoming, lambda {
    joins(:additional_dates).where('additional_dates.end_at >= ?', Date.today).order('start_at ASC')
  }

  def start_at
    additional_dates.where(label: 'Date').first.try(:start_at)  ||
      additional_dates.first.try(:start_at) ||
      super
  end

  def end_at
    additional_dates.where(label: 'Date').first.try(:end_at) ||
      additional_dates.first.try(:end_at) ||
      super
  end

  
  private


  def update_details(doc)
    %w[website location organizers].each do |method|
      node = doc.at("li:contains('#{method.titleize}')")
      send("#{method}=", node.text.split(':').last) if node
    end
    self.website = "http:#{website}" if website
    #    date_nodes = doc.xpath("//li[contains(text(), 'Date')]") #+ doc.xpath("//li[contains(text(), 'date')]")
    date_nodes = doc.css("li:contains('Date')") +  doc.css("li:contains('date:')")
    date_nodes.each do |date_node|
      puts date_node.text
      update_dates(date_node.text.to_s) if date_node
      date_node.try(:remove)
    end
    doc.at("strong:contains('Description')").try(:remove)
  end


  def update_dates(date_text)
    puts date_text
    if date_text.match(/\d{1,2}-\d{1,2}-\d{2,4}/)
      dates = date_text.split(':').last.split('- ')
    else
      dates = date_text.split(':').last.split('-')
    end
    puts dates.inspect
    date = AdditionalDate.create(label: date_text.split(':').first)
    date.update_dates(dates)
    additional_dates << date
  end

end
