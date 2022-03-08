# frozen_string_literal: true

# handle multiple dates for events
class AdditionalDate < ApplicationRecord
  belongs_to :event
  has_many :additional_date_values


  include Dateable

  def self.make_date(label_text, dates, event)
    event.additional_dates.where(label: label_text).each(&:delete) if ['Start Date', 'End Date'].include?(label_text)
    date = create(
      label: label_text,
      event: event
    )
    dates.split(';').each do |datetime|
      date.additional_date_values << AdditionalDateValue.create(date: Chronic.parse(datetime).try(:to_date))
    end
  end
end
