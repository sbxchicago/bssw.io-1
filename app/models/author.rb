# frozen_string_literal: true

# contributor of a resource
class Author < ApplicationRecord
  include ActionView::Helpers::TextHelper

  has_many :contributions, autosave: false
  has_many :site_items, through: :contributions

  extend FriendlyId
  friendly_id :last_name, use: %i[finders slugged scoped], scope: :rebuild_id

  scope :displayed, lambda {
    where("#{table_name}.rebuild_id = ?", RebuildStatus.first.display_rebuild_id)
  }

  def should_generate_new_friendly_id?
    (new_record? || slug.nil?) && !last_name.blank?
  end

  def display_name
    "#{first_name} #{last_name}"
  end

  def single_contribution(preview: false)
    nums = [resource_count(preview: preview),
            event_count(preview: preview),
            blog_count(preview: preview)]
    nums.sort == [0, 0, 1]
  end

  def resource_count(preview: false)
    (preview ? SiteItem.preview : SiteItem.published).displayed.with_author(self).count -
      blog_count(preview: preview) -
      event_count(preview: preview)
  end

  def blog_count(preview: false)
    (preview ? BlogPost.preview : BlogPost.published).displayed.with_author(self).count
  end

  def event_count(preview: false)
    (preview ? Event.preview : Event.published).displayed.with_author(self).count
  end

  store_methods :resource_count, :blog_count, :event_count, :resource_listing, :blog_listing, :event_listing

  def resource_listing
    "#{resource_count} #{'resource'.pluralize(resource_count)}"
  end

  def blog_listing
    "#{blog_count} #{'blog post'.pluralize(blog_count)}"
  end

  def event_listing
    "#{event_count} #{'event'.pluralize(event_count)}"
  end

  def update_from_github
    return unless website&.match('github')
    return unless affiliation.blank? || avatar_url.blank?

    client = GithubImporter.github
    client.login
    begin
      update_info(client.user(website.split('/').last))
    rescue Octokit::NotFound
      # if we have an invalid GH id, don't worry about it
    end
  end

  def update_info(hash)
    update(avatar_url: hash.avatar_url.gsub(/\?v=[[:digit:]]/, ''))
    update(affiliation: hash.company) if affiliation.blank?
    names = AuthorUtility.names_from(hash.name)
    update(first_name: names.first, last_name: names.last, alphabetized_name: names.last) unless names == [nil, nil]
  end

  def do_overrides(vals)
    return unless vals[1]

    update(alphabetized_name: vals[1].strip)
    return unless vals[2]

    names = AuthorUtility.names_from(vals[2])
    update(first_name: names.first, last_name: names.last)
  end

  def self.find_from_vals(vals, rebuild)
    if vals.first == '-'
      names = AuthorUtility.names_from(vals.last)
      find_by(rebuild_id: rebuild, first_name: names.first, last_name: names.last)
    else
      find_by(rebuild_id: rebuild, website: "https://github.com/#{vals.first}")
    end
  end
end
