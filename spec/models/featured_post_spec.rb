# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeaturedPost, type: :model do
  it 'might have an image' do
    fp = FactoryBot.create(:featured_post, path: 'image.jpg')
    expect(fp.image?).to be_truthy
    expect(fp.image).to be_a String
  end
  it 'might have a site item' do
    item = FactoryBot.create(:site_item)
    fp = FactoryBot.create(:featured_post, path: "blah/#{item.slug}")
    expect(fp.site_item.id).to eq item.id
  end
end
