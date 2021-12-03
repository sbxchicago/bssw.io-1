# frozen_string_literal: true

# Events e.g. conferences
class Event < Searchable
  include Dateable

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
  has_many :additional_dates

  def update_from_content(doc, rebuild)
    update_details(doc)
    overview = doc.at("p:contains('Overview')")
    overview&.remove
    super(doc, rebuild)
  end

  scope :upcoming, lambda {
                     left_outer_joins(additional_dates: :additional_date_values).where('additional_date_values.date >= ?', Date.today)
                   }

  scope :past, lambda {
                 left_outer_joins(additional_dates: :additional_date_values).where('additional_date_values.date < ?', Date.today)
               }

  def special_additional_dates
    additional_dates.where('label != ?', 'Start Date').where('label != ?', 'End Date')
  end

  private

  def update_details(doc)
    %w[website location organizers].each do |method|
      node = doc.at("li:contains('#{method.titleize}')")
      send("#{method}=", node.text.split(':').last) if node
    end
    self.website = "http:#{website}" if website
    date_nodes = doc.css("li:contains('Date')") + doc.css("li:contains(' date')")
    update_dates(date_nodes) if date_nodes

    doc.at("strong:contains('Description')").try(:remove)
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
        AdditionalDate.make_date('Start Date', dates.first, self)
        AdditionalDate.make_date('End Date', dates.last, self)
      elsif label_text == 'Date'
        AdditionalDate.make_date('Start Date', dates.first, self)
      else
        AdditionalDate.make_date(label_text, date_text, self)
      end
      date_node.try(:remove)
    end
    fix_end_year(start_date, end_date)
  end
end
