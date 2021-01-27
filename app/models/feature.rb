# frozen_string_literal: true

# link communities to featured resources
class Feature < ApplicationRecord
  belongs_to :resource
  belongs_to :community
end
