# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatIs, type: :model do
  it 'can create itself from content' do
    content = "# Foo \n#### Contributed by [Jane Does](https://github.com)\n
\n#### Publication Date: May 1, 2020 \n bar
<!---
Topics: foo, bar
Categories: Blah Blah
Publish: true
Aggregate: Base
--->"
    FactoryBot.create(:category, name: 'Better Blah Blah')

    res = Resource.find_or_create_resource('CuratedContent/HowToFoo.md', 1)
    expect(res).to be_a(HowTo)
    expect(res.basic?).to be true
    res.parse_and_update(content, RebuildStatus.displayed_rebuild.id)
    res.reload
    expect(res.content).to match 'bar'
    expect(res.topics).not_to be_empty
    expect(res.categories).not_to be_empty
    expect(res.authors.map(&:last_name).to_s).to match 'Doe'
  end
end
