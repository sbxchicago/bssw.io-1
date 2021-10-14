# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatIs, type: :model do
  it 'can create itself from content' do
    content = "# Foo \n#### Contributed by [Jane Does](https://github.com)\n \n bar
\n#### Publication Date: May 1, 2020
<!---
Topics: first topic, second topic
Categories: Blah Blah
Publish: true
Aggregate: Base
--->"
    FactoryBot.create(:category, name: 'Better Blah Blah')
    what_is = Rebuild.create.find_or_create_resource('CuratedContent/WhatIsFoo.md')
    expect(what_is).to be_a(WhatIs)
    expect(what_is.basic?).to be true
    what_is.parse_and_update(content)
    expect(what_is.content).to match 'bar'
    topic = what_is.topics.last
    resource = FactoryBot.create(:resource)
    resource.topics << topic
  end
end
