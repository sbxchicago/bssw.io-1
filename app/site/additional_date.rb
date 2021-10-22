class AdditionalDate < ApplicationRecord
  belongs_to :event

  def broken_range?
    end_at && start_at > end_at
  end

  def update_dates(dates)
    puts self.label
    puts dates
    self.start_at = Chronic.parse(dates.first)
    get_end_date(dates.last)
  end

  def get_end_date(end_text)
    end_text = "#{start_at.strftime('%B')} #{end_text}" unless begin
                                                                 Date.parse(end_text)
                                                               rescue StandardError
                                                                 false
                                                               end
    self.end_at = Chronic.parse(end_text)
    fix_end_year(end_text)
  end

  def fix_end_year(end_text)
    end_year = end_text.match(/\d{4}/)
    if broken_range? && end_year
      self.start_at = start_at.change(year: end_year[0].to_i)
    elsif broken_range?
      self.start_at = end_at.change(year: end_at.year + 1)
    end
  end
  
end
