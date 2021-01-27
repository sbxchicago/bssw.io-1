# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rebuild, type: :model do
  it 'exists' do
    expect(Rebuild.new).to be_a(Rebuild)
  end
end
