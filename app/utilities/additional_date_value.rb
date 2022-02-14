# frozen_string_literal: true

class AdditionalDateValue < ApplicationRecord
  belongs_to :additional_date
  delegate :event, to: :additional_date

  scope :from_events, lambda { |events|
                        joins(additional_date: 'event').includes([additional_date: :event]).where('additional_dates.label != ?', 'End Date').where('site_items.id in (?)', events.map(&:id))
  }

  def self.get_from_events(events, past)
    values = from_events(events).to_a
    date_groups = values.group_by{|d| [ d.additional_date.event_id, d.additional_date.label ]}
    date_groups.each{ |dg|
      next if dg.last.size == 1
      if past
        new_dates = dg.last.select{|d| d.date < Date.today }.sort_by(&:date)
        dates = dg.last.to_a - [new_dates.last]
      else
        new_dates = dg.last.select{|d| d.date >= Date.today }.sort_by(&:date)
        dates = dg.last.to_a - [new_dates.first]
      end
      values.delete_if{|v| v.in?(dates)}
    }
    return values
  end

end
