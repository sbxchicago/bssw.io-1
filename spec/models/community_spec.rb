# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Community, type: :model do
  describe 'with some content...' do
    before(:each) do
      FactoryBot.create(:resource, base_path: 'itspath.md')
      content = "# Foo \n#### Contributed by [Jane Does](https://github.com)\n \n bar\n
<!-- Featured resources: -->
- [A Resource](/itspath.md)
<!---
Topics  : foo, bar
Categories: Blah Blah
Publish: true
Aggregate: Base
--->"

      @community = GithubImporter.find_or_create_resource('stuff/Site/Communities/foo.md', 1)
      @community.parse_and_update(content, RebuildStatus.displayed_rebuild.id)
    end

    it 'can create itself from content' do
      expect(@community).to be_a(Community)
      expect(@community.path).to eq 'Site/Communities/foo.md'
      expect(@community.name).to eq 'Foo'
    end
    it 'updates resources' do
      expect(@community.resources).not_to be_empty
    end
  end
end
