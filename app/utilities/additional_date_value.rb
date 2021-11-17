# frozen_string_literal: true

class AdditionalDateValue < ApplicationRecord
  belongs_to :additional_date
  delegate :event, to: :additional_date

  scope :from_events, lambda { |events|
                        joins(additional_date: 'event').includes([additional_date: :event]).where('additional_dates.label != ?', 'End Date').where('site_items.id in (?)', events.map(&:id))
                      }
end
