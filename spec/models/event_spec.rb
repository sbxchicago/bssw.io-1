# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do
  it 'can create itself from content' do
    content = "# Foo \n bar
        \n* Dates: December 3, #{Date.today.year} - January 5
        \n* Location: Place \n* \n* <!--- Publish: Yes --->"

    event = Resource.find_or_create_resource('stuff/Events/foo.md', 1)
    expect(event).to be_a(Event)
    expect(event.path).to eq 'Events/foo.md'
    event.parse_and_update(content, RebuildStatus.displayed_rebuild.id)
    event.reload
    event.update_attribute(:publish, true)
    expect(event.name).to eq 'Foo'
    expect(event.content).to match 'bar'
    expect(event.start_at).not_to be_nil
    expect(event.start_at).to be < event.end_at
    expect(event.location).to match 'Place'
    expect(Event.past).not_to include(event)
    expect(Event.upcoming).to include(event)
  end

  it 'can parse written dates' do
    content = "# Foo \n bar
    \n* Dates: 10-9-18 - 1-25-19
    \n* Location: Place \n* \n* <!--- Publish: Yes --->"

    event = Resource.find_or_create_resource('Events/foo.md', 1)
    event.parse_and_update(content, RebuildStatus.displayed_rebuild.id)
    expect(event.start_at).to eq Chronic.parse('October 9 2018').to_date
  end

  it 'can parse dates from earlier this year' do
    content = "# Foo \n bar
    \n* Dates: February 1 - March 2 #{Date.today.year}
    \n* Location: Place \n* \n* <!--- Publish: Yes --->"

    event = Resource.find_or_create_resource('Events/foo.md', 1)
    event.parse_and_update(content, RebuildStatus.displayed_rebuild.id)
    expect(event.start_at).to eq Chronic.parse("February 1 #{Date.today.year}").to_date
  end

  it 'can parse dates from later this year' do
    content = "# Foo \n bar
    \n* Dates: December 1 - December 20 #{Date.today.year}
    \n* Location: Place \n* \n* <!--- Publish: Yes --->"
    event = Resource.find_or_create_resource('Events/foo.md', 1)
    event.parse_and_update(content, RebuildStatus.displayed_rebuild.id)
    expect(event.start_at).to eq Chronic.parse("December 1 #{Date.today.year}").to_date
  end

  it 'can parse dates across years' do
    content = "# Foo \n bar
    \n* Dates: December 1 #{Date.today.year} - January 2
     \n* Location: Place \n* \n* <!--- Publish: Yes --->"

    event = Resource.find_or_create_resource('Events/foo.md', 1)
    event.parse_and_update(content, RebuildStatus.displayed_rebuild.id)
    expect(event.start_at).to eq Chronic.parse("December 1 #{Date.today.year}").to_date
    expect(event.end_at).to eq Chronic.parse("January 2 #{Date.today.year + 1}").to_date
  end
end
