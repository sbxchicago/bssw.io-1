# frozen_string_literal: true

class AdditionalDate < ApplicationRecord
  belongs_to :event
  has_many :additional_date_values

  include Dateable

  def self.make_date(label_text, dates, event)
    date = create(
      label: label_text,
      event: event
    )
    puts dates
    dates.split(';').each do |datetime|
      puts datetime
      date.additional_date_values << AdditionalDateValue.create(date: Chronic.parse(datetime).try(:to_date))
    end
  end
end
