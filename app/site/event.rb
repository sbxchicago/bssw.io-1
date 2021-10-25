# frozen_string_literal: true

# Events e.g. conferences
class Event < Searchable

  include Dateable

  self.table_name = 'site_items'
  has_many :additional_dates
  
  def update_from_content(doc, rebuild)
    update_details(doc)
    overview = doc.at("p:contains('Overview')")
    overview&.remove
    super(doc, rebuild)
  end
  scope :upcoming, lambda {
left_outer_joins(:additional_dates).where('site_items.end_at >= ?', Date.today).or(left_outer_joins(:additional_dates).where('additional_dates.end_at >= ?', Date.today)).distinct }

  scope :past, lambda {
left_outer_joins(:additional_dates).where('site_items.end_at < ?', Date.today).or(left_outer_joins(:additional_dates).where('additional_dates.end_at < ?', Date.today)).distinct }

     def next_date
     array = [["Dates", self.start_at, self.end_at]] + self.additional_dates.map{|d| [d.label, d.start_at, d.end_at]}
     array.delete_if {|tuple| tuple.last && tuple.last < Date.today }
     array = array.sort_by { |tup| tup[1] || tup[2] }
     array.first
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

  
  def update_dates(date_nodes)
    date_nodes.each do |date_node|
      text = date_node.text
      dates = if text.match(/\d{1,2}-\d{1,2}-\d{2,4}/)
                text.split(':').last.split('- ')
              else
                text.split(':').last.split('-')
              end

      if text.match(/^Date/)
        self.start_at = Chronic.parse(dates.first).try(:to_date)
        get_end_date(dates.last)
      else
        label = text.split(':').first
        date = AdditionalDate.create(
          label: label,
          event: self,
          start_at: Chronic.parse(dates.first).try(:to_date),
        )
        date.get_end_date(dates.last)
        date.save
      end
    date_node.try(:remove)
    end
  end

end
