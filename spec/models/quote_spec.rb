# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Quote, type: :model do
  it 'can create itself from content' do
    content = "- Foo --bar \n- baz --ban"

    Quote.import(content)
    expect(Quote.find_by_text('Foo ').author).to match 'bar'
    expect(Quote.find_by_author('ban').text).to match 'baz'
  end
end
