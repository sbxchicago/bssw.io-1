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
    displayed.each do |auth|
      auth.refresh_resource_count
      auth.refresh_event_count
      auth.refresh_blog_count
      auth.refresh_resource_listing
      auth.refresh_blog_listing
      auth.refresh_event_listing
    end
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
      names = self.names_from(link.text)
      website = URI.parse(link['href'])
      if website.host.blank?
        website = nil
      else
        website = "https://#{website.host}#{website.path}"
      end
      auth = find_by(website: website, rebuild_id: rebuild)
      unless auth
        auth = find_or_create_by(rebuild_id: rebuild, last_name: names.last, first_name: names.first)
        auth.update(website: website, alphabetized_name: names.last)
      end
      link.remove
      authors << auth
    end
    txt = node.text.gsub('Contributed by', '')
    txt = txt.gsub(' and ', ',').strip
    txt.split(',').each do |text|
      next if text.blank? || text.match?("\:") || text.match?("\#")
      names = self.names_from(text)
      auth = find_or_create_by(rebuild_id: rebuild, last_name: names.last, first_name: names.first)
      auth.update(alphabetized_name: names.last)
      authors << auth
    end

    authors
  end

  def update_info(hash)
    update(avatar_url: hash.avatar_url.gsub(/\?v=[[:digit:]]/, ''))
    update(affiliation: hash.company) if affiliation.blank?
    names = Author.names_from(hash.name)
    update(first_name: names.first, last_name: names.last, alphabetized_name: names.last) unless names == [nil, nil]
  end

  def self.names_from(name)
    return [nil, nil] unless name.respond_to?(:split)
    names = name.split(' ')
    names = names.map{|n| n.blank? ? nil : n }
    last_name = names.last 
    first_name = [names - [last_name]].join(' ')
    return [first_name, last_name]
  end

  def update_from_link(link)
    parent = link.parent
    siblings = parent.children
    siblings.each do |kid|
      process_kid(kid)
    end
    names = Author.names_from(siblings.first.text)
    update(first_name: names.first, last_name: names.last, alphabetized_name: names.last)
    siblings.first.try(:remove)
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

  def self.process_overrides(doc, rebuild)
    comments = doc.xpath('//comment()') if doc
    comments&.each do |comment|
      next unless comment.text.match?(/Overrides/i)
      array = comment.text.split(/\n/).collect do |val|
        next if val.match?(/Overrides/i)
        vals = val.split(',')
        vals = vals.map{|v| v.delete('"')}
        author = Author.find_by(rebuild_id: rebuild, website: "https://github.com/#{vals.first}")
        next unless author && vals[1]
        author.update(alphabetized_name: vals[1].strip)
        next unless vals[2]
        names = Author.names_from(vals[2])
        author.update(first_name: names.first, last_name: names.last)
      end
    end
  end
  
end
