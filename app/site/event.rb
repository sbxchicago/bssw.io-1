# frozen_string_literal: true

# Events e.g. conferences
class Event < SiteItem
  include Dateable
  has_many :additional_dates
  has_many :additional_date_values, -> { order(date: :asc) }, through: :additional_dates  

  scope :upcoming, -> { left_outer_joins(:additional_dates).includes(:additional_date_values).where('additional_date_values.date >= ?', Date.today).order('additional_date_values.date asc').distinct  }

  scope :past, -> { left_outer_joins(:additional_dates).includes(:additional_date_values).where('additional_date_values.date < ?', Date.today).order('additional_date_values.date desc').distinct  }

  
  def next_date
    additional_date_values.joins(:additional_date).where('date >= ?', Date.today).where("additional_dates.label != 'End Date'").first
  end

  def prev_date
    additional_date_values.joins(:additional_date).where('date < ?', Date.today).where("additional_dates.label != 'End Date'").last
  end
  
  def start_date
    additional_dates.where(label: 'Start Date').first
  end

  def start_at
    start_date.try(:additional_date_values).try(:first).try(:date)
  end

  def end_date
    additional_dates.where(label: 'End Date').first
  end

  def end_at
    end_date.try(:additional_date_values).try(:first).try(:date)
  end

  self.table_name = 'site_items'


  def update_from_content(doc, rebuild)
    update_details(doc)
    overview = doc.at("p:contains('Overview')")
    overview&.remove
    super(doc, rebuild)
  end

  def special_additional_dates
    additional_date_values.where('additional_date_id in (?)', additional_dates.where('label != ?', 'Start Date').where('label != ?', 'End Date').map(&:id))
  end

  private

  def update_details(doc)
    %w[location organizers].each do |method|
      node = doc.at("li:contains('#{method.titleize}')")
      send("#{method}=", node.text.split(':').last) if node
      node.try(:remove)
    end
    if doc.at("li:contains('Website')")
      set_website(doc.at("li:contains('Website')"))
      self.website = "http:#{website}" if website
    end
    date_nodes = doc.css("li:contains('Date')") + doc.css("li:contains(' date')") + doc.css("li:contains('Deadline')") + doc.css("li:contains('deadline')")
    update_dates(date_nodes) if date_nodes
    doc.at("strong:contains('Description')").try(:remove)
  end

  def set_website(node)
    url = node.text
    match = url.match('\[(.*?)\](.*)')
    if match
       self.update_attribute(:website_label, match[1])
       self.update_attribute(:website, match[2])
       node.remove
     else
      self.website=(url)
    end
    node.try(:remove)
  end
  
  def update_dates(date_nodes)
    date_nodes.each do |date_node|
      text = date_node.text.split(':')
      date_text = text.last
      label_text = text.first
      dates = if date_text.match(/\d{1,2}-\d{1,2}-\d{2,4}/)
                date_text.split('- ')
              else
                date_text.split('-')
              end
      if dates.size > 1
        end_year = dates.last.match(/\d{4}/)
        dates = ["#{dates.first} #{end_year}", dates.last] unless dates.first.match(/\d{4}/)
        months = Date::MONTHNAMES.slice(1..-1).map(&:to_s).map { |m| m[0, 3] }
        our_month = nil
        end_month = false
        months.each do |month|
          our_month = month if dates.first.match(month)
          end_month = true if dates.last.match(month)
        end
        dates = [dates.first, "#{our_month} #{dates.last}"] if our_month && !end_month
        AdditionalDate.make_date('Start Date', dates.first, self)
        AdditionalDate.make_date('End Date', dates.last, self)
      # elsif label_text.strip == 'Date'
      #   AdditionalDate.make_date('Date', dates.first, self)
      else
        AdditionalDate.make_date(label_text, date_text, self)
      end
      date_node.try(:remove)
    end
    fix_end_year(start_date, end_date)
  end
end
