# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkdownImport, type: :model do
  it 'provides a fully qualified path' do
    path = 'http://example.com/image.jpg'
    modified_path = MarkdownImport.modified_path(path)
    expect(modified_path).to match('http://example.com/image.jpg')
  end

  it 'provides an adjusted path' do
    path = 'foo.jpg'
    modified_path = MarkdownImport.modified_path(path)
    expect(modified_path).to match('/master/images/foo.jpg')
  end

  it 'maintains subdirectories' do
    path = '../images/foo/foo.jpg'
    modified_path = MarkdownImport.modified_path(path)
    expect(modified_path).to match('/master/images/foo/foo.jpg')
  end
end
