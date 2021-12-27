# frozen_string_literal: true

module Dateable
  def broken_range?
    end_at && start_at > end_at
  end

  def fix_end_year(start_date, _end_date)
    return unless start_at && end_at

    start_date.additional_date_values.first.update(date: start_at.to_date.change(year: end_at.year)) if broken_range?
    if broken_range?
      start_date.additional_date_values.first.update(date: start_at.to_date.change(year: end_at.year - 1))
    end
  end
end
