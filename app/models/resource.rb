# frozen_string_literal: true

# The basic Resource class
class Resource < SiteItem
  after_create :set_stuff_up

  def set_stuff_up
    self.type = 'Resource'
    self.aggregate = 'base' unless aggregate
    save
  end
end
