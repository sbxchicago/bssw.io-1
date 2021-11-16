# frozen_string_literal: true

class AdditionalDateValue < ApplicationRecord
  belongs_to :additional_date
  delegate :event, to: :additional_date

  # scope :from_events, lambda { |events|
  #   joins('additional_date').where('additional_dates.event_id in ?' , events).where("additional_dates.label != 'End Date'")  }

#  scope :from_events, lambda { |events| inner_joins(additional_date: 'event').where('events.id in ?', events) }

  scope :from_events, lambda { |events| joins(additional_date: 'event').where('additional_dates.label != ?', 'End Date').where('site_items.id in (?)', events.map(&:id)) }
  
end
