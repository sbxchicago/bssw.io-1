class AdditionalDate < ApplicationRecord
  belongs_to :event

  include Dateable 

  def self.make_date(label_text, dates, event)
    date = self.create(
      label: label_text,
      event: event,
      start_at: Chronic.parse(dates.first).try(:to_date),
    )
    date.get_end_date(dates.last)
    date.save
  end
  
end
