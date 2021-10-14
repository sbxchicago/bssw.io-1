# frozen_string_literal: true

class Contribution < ApplicationRecord
  belongs_to :author, dependent: :destroy
  belongs_to :site_item, dependent: :destroy
end
