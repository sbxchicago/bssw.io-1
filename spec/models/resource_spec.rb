# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Resource, type: :model do
  before(:each) do
    FactoryBot.create(:page, name: 'Resources')
  end

  it 'can create itself from content' do
    FactoryBot.create(:page, path: 'foo.md')
    content = "# Foo \n#### Contributed by [Jane Does](https://github.com)\n \n bar
\n#### Publication Date: June 1, 2020
![bloo](blah.jpg)[okay]

<img src='blaj.jpg' class='lightbox'>

[fooble](foo.md)

<!---
Topics: foo, bar
Categories: Blah Blah
Publish: yes
Aggregate: Base
RSS update: 01-01-18
--->"

    FactoryBot.create(:category, name: 'Better Blah Blah')

    res = GithubImporter.find_or_create_resource('stuff/CuratedContent/foo.md', 1)
    expect(res).to be_a(Resource)
    expect(res.path).to eq 'CuratedContent/foo.md'
    res.parse_and_update(content, RebuildStatus.displayed_rebuild.id)
    res.reload
    expect(res.name).to eq 'Foo'
    expect(res.content).to match 'bar'
    expect(res.topics).not_to be_empty
    expect(res.categories).not_to be_empty
    expect(res.authors.map(&:last_name).to_s).to match 'Doe'
    expect(res.main).to be_a(String)
    expect(res.snippet).to be_a(String)
    res.update_links_and_images
  end
end
