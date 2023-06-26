# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contribute, type: :model do
  it 'exists' do
    cont = Contribute.new(name: 'foo', email: 'foo@example.com')
    expect(cont.headers.to_s).to match 'Contribution'
  end
end
