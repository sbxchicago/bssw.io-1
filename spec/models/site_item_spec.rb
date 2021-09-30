# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SiteItem, type: :model do
  it 'shows the preview and published stuff' do
    previewer = FactoryBot.create(:resource, preview: true, publish: false)
    published = FactoryBot.create(:resource, rss_date: Date.today, published_at: Date.today, aggregate: 'base')
    hidden = FactoryBot.create(:resource, publish: false)
    expect(SiteItem.preview).to include(previewer)
    expect(SiteItem.preview).to include(published)
    expect(SiteItem.preview).not_to include(hidden)
    expect(SiteItem.published).not_to include(previewer)
  end

  it 'deals with topics + categories' do
    resource = FactoryBot.create(:resource, aggregate: 'base')
    top = FactoryBot.create(:topic, name: 'foo')
    cat = FactoryBot.create(:category, name: 'bar')
    top.category = cat
    resource.topics << top
    second_resource = FactoryBot.create(:resource)
    expect(SiteItem.with_topic(top)).to include(resource)
    expect(SiteItem.with_category(cat)).to include(resource)
    expect(SiteItem.with_category(cat)).not_to include(second_resource)
  end
end
