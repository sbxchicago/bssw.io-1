# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdditionalDate, type: :model do
  it "has values" do
    event = FactoryBot.create(:event)
    event.additional_dates <<
      FactoryBot.create(:additional_date, additional_date_values:[FactoryBot.create(:additional_date_value, date: 1.week.ago)], label: 'Date' )
    event.additional_dates << FactoryBot.create(:additional_date, additional_date_values:[FactoryBot.create(:additional_date_value, date: 2.weeks.ago)], label: 'Date' )
    event.additional_dates << FactoryBot.create(:additional_date, additional_date_values:[FactoryBot.create(:additional_date_value, date: 3.weeks.ago)], label: 'Date' )
    event.additional_dates <<
      FactoryBot.create(:additional_date, additional_date_values:[FactoryBot.create(:additional_date_value, date: 1.week.from_now)], label: 'Date' )
    event.additional_dates <<
      FactoryBot.create(:additional_date, additional_date_values:[FactoryBot.create(:additional_date_value, date: 2.weeks.from_now)], label: 'Date' )
    event.additional_dates << FactoryBot.create(:additional_date, additional_date_values:[FactoryBot.create(:additional_date_value, date: 3.weeks.from_now)], label: 'Date' )
    puts "past"
    AdditionalDateValue.get_from_events(Event.all, true)
    puts "future"
    AdditionalDateValue.get_from_events(Event.all, false)

  end

end
