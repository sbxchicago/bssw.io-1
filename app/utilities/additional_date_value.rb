# frozen_string_literal: true

# handle multiple dates for events, with and without specific labels
class AdditionalDateValue < ApplicationRecord
  belongs_to :additional_date
  delegate :event, to: :additional_date

  
  scope :from_events, lambda { |events|
    joins(
      additional_date: 'event'
    ).includes([additional_date: :event]).where(
      'additional_dates.label != ?', 'End Date'
    ).where('site_items.id in (?)', events.map(&:id))
  }

  def self.get_from_events(events, past)
    values = from_events(events)
    date_groups = values.group_by { |d| [d.additional_date.event_id, d.additional_date.label] }
    date_groups.each do |dg|
      next if dg.last.size == 1

      dates = process_date_group(dg, past)
      values = values.where('additional_date_values.id not in (?)', dates.map(&:id))
    end
    values
  end

  def self.process_date_group(dg, past)
    if past
      new_dates = dg.last.select { |d| d.date < Date.today }.sort_by(&:date)
      dates = dg.last.to_a - [new_dates.last]
    else
      new_dates = dg.last.select { |d| d.date >= Date.today }.sort_by(&:date)
      dates = dg.last.to_a - [new_dates.first]
    end
    dates
  end
end
