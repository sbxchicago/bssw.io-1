# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchable, type: :model do
  it 'can search' do
    @rebuild = Rebuild.create
    RebuildStatus.all.each(&:destroy)
    RebuildStatus.create(display_rebuild_id: @rebuild.id)
    event = FactoryBot.create(:event, name: 'foo', content: 'foo', rebuild_id: @rebuild.id)
    FactoryBot.create(:event, name: 'bar', rebuild_id: @rebuild.id)
    expect(Searchable.perform_search(Searchable.prepare_strings('foo'), 1, nil)).to include(event)
  end
end
