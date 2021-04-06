# frozen_string_literal: true

# contributor of a resource
class Author < ApplicationRecord
  include ActionView::Helpers::TextHelper

  has_many :contributions, autosave: false
  has_many :site_items, through: :contributions

  #  validates_uniqueness_of :website, scope: :rebuild_id

  extend FriendlyId
  friendly_id :last_name, use: %i[finders slugged scoped], scope: :rebuild_id

  scope :displayed, lambda {
    where("#{table_name}.rebuild_id = ?", RebuildStatus.displayed_rebuild)
  }

  def should_generate_new_friendly_id?
    (new_record? || slug.nil?) && !last_name.blank?
  end

  def self.process_authors(rebuild)
    where(rebuild_id: rebuild).each(&:update_from_github)
  end

  def self.refresh_author_counts
    displayed.each do |auth|
      auth.refresh_resource_count
      auth.refresh_event_count
      auth.refresh_blog_count
      auth.refresh_resource_listing
      auth.refresh_blog_listing
      auth.refresh_event_listing
    end
  end

  def single_contribution(preview = false)
    nums = [resource_count(preview),
            event_count(preview),
            blog_count(preview)]
    nums.sort == [0, 0, 1]
  end

  def resource_count(preview = false)
    (preview ? SiteItem.preview : SiteItem.published).displayed.with_author(self).count -
      blog_count(preview) -
      event_count(preview)
  end

  def blog_count(preview = false)
    (preview ? BlogPost.preview : BlogPost.published).displayed.with_author(self).count
  end

  def event_count(preview = false)
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
    return unless website
    return unless affiliation.blank? || avatar_url.blank?

    client = GithubImport.github
    client.login

    begin
      hash = client.user(website.split('/').last)
      update(avatar_url: hash.avatar_url.gsub(/\?v=[[:digit:]]/, ''))

      update(affiliation: hash.company) if affiliation.blank?

      update_name(hash.name)
    rescue StandardError
    end
  end

  def self.make_from_data(node, rebuild)
    authors = []
    node.css('a').each do |link|
      auth = find_or_create_by(website: link['href'].split('/').try(:last), rebuild_id: rebuild)
      auth.update_name(link.text) if auth.last_name.blank?
      authors << auth
    end
    authors
  end

  def update_name(author_name)
    names = author_name.split(' ')
    last_name = names.last
    update(
      first_name: [names - [last_name]].join(' '), last_name: last_name
    )
  end

  def update_from_link(link)
    siblings = link.parent.children
    siblings.each do |kid|
      kid.remove if kid.text.blank?
      if kid.text.match?('Title')
        update_attribute(:title, kid.text.gsub('Title: ', ''))
        kid.remove
      end
    end
    update_name(siblings.first.text)
    siblings.first.remove
    update_attribute(:affiliation,
                     link.parent.children.first.text.strip)
  end
end
