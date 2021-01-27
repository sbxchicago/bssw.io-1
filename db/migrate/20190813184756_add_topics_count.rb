# frozen_string_literal: true

class AddTopicsCount < ActiveRecord::Migration[5.0]
  def up
    add_column :site_items, :topics_count, :integer
    SiteItem.find_each do |item|
      item.update_attribute(:topics_count, item.topics.size)
    end
  end

  def down
    remove_column :site_items, :topics_count
  end
end
