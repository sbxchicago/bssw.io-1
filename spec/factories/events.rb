# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    name { (0...8).map { rand(65..90).chr }.join }
    path { (0...8).map { rand(65..90).chr }.join }
    start_at { 3.weeks.ago }
    end_at { 1.week.from_now }
    location { 'MyString' }
    aggregate { 'base' }
    website { 'MyString' }

    publish { true }
    type { 'Event' }
  end
end
