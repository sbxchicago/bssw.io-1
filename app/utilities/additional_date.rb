# frozen_string_literal: true

# handle multiple dates for events
class AdditionalDate < ApplicationRecord
  belongs_to :event
  has_many :additional_date_values, dependent: :destroy

  include Dateable

  def self.make_date(label_text, dates, event)
    event.save


    if label_text.match('Start ') || label_text.match('End ')
      event.additional_dates.where(label: label_text).each(&:delete)
    end
    date = create(
      label: label_text,
      event: event
    )
    dates.split(';').each do |datetime|
      date.additional_date_values << AdditionalDateValue.new(date: Chronic.parse(datetime).try(:to_date))
    end
  end
end
