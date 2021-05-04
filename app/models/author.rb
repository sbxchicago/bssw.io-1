# frozen_string_literal: true

# contributor of a resource
class Author < ApplicationRecord
  include ActionView::Helpers::TextHelper

  has_many :contributions, autosave: false
  has_many :site_items, through: :contributions

  extend FriendlyId
  friendly_id :last_name, use: %i[finders slugged scoped], scope: :rebuild_id

  scope :displayed, lambda {
    where("#{table_name}.rebuild_id = ?", RebuildStatus.displayed_rebuild)
  }

  def should_generate_new_friendly_id?
    (new_record? || slug.nil?) && !last_name.blank?
  end

  def display_name
    "#{first_name} #{last_name}"
  end

  def self.process_authors(rebuild)
    where(rebuild_id: rebuild).each(&:update_from_github)
  end

  def self.refresh_author_counts
    # displayed.each do |auth|
    #   auth.refresh_resource_count
    #   auth.refresh_event_count
    #   auth.refresh_blog_count
    #   auth.refresh_resource_listing
    #   auth.refresh_blog_listing
    #   auth.refresh_event_listing
    # end
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

  # store_methods :resource_count, :blog_count, :event_count, :resource_listing, :blog_listing, :event_listing

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
      update_info(client.user(website.split('/').last))
    rescue Octokit::NotFound
      # if we have an invalid GH id, don't worry about it
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

  def update_info(hash)
    update(avatar_url: hash.avatar_url.gsub(/\?v=[[:digit:]]/, ''))
    update(affiliation: hash.company) if affiliation.blank?
    name = hash.name
    return unless name.respond_to?(:split)

    update_name(name)
  end

  def update_name(name)
    names = name.split(' ')
    last_name = names.last
    update(
      first_name: [names - [last_name]].join(' '), last_name: last_name
    )
  end

  def update_from_link(link)
    parent = link.parent
    siblings = parent.children
    siblings.each do |kid|
      process_kid(kid)
    end
    update_name(siblings.first.text)
    siblings.first.remove
    update_attribute(:affiliation,
                     parent.children.first.text.strip)
  end

  def process_kid(kid)
    text = kid.text
    kid.remove if text.blank?
    return unless text.match?('Title')

    update_attribute(:title, text.gsub('Title: ', ''))
    kid.remove
  end
end
