# frozen_string_literal: true

# store the current rebuild
class RebuildStatus < ApplicationRecord
  def self.displayed_rebuild
    Rebuild.find(first.display_rebuild_id)
  end

  def self.in_progress_rebuild
    Rebuild.find(first.in_progress_rebuild_id)
  end

  def self.content_branch
    displayed_rebuild.content_branch
  end

  def self.code_branch
    first.code_branch
  end

  def self.set_code_branch(name)
    first.update(code_branch: name)
  end

  def self.start(rebuild)
    status = first || create
    status.update_attribute(:in_progress_rebuild_id, rebuild.id)
  end

  def self.complete(rebuild)
    first.update(display_rebuild_id: rebuild.id, in_progress_rebuild_id: nil)
    rebuild.update(files_processed: "<ul>#{rebuild.files_processed}</ul>",
                   ended_at: Time.now)
  end
end
