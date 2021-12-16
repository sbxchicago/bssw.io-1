# frozen_string_literal: true

# resources, events, and blog posts
class SiteItem < MarkdownImport

  extend Searchable

#  before_save :set_search_text
  
  self.table_name = 'site_items'
  
  has_and_belongs_to_many :topics, -> { distinct }
  has_many :contributions, dependent: :destroy
  has_many :authors, through: :contributions
  has_and_belongs_to_many :communities, through: :features, class_name: 'Resource'

  has_many :features

  
  validates_uniqueness_of :path, optional: true, case_sensitive: false, scope: :rebuild_id
  has_many :announcements

  extend FriendlyId
  friendly_id :slug_candidates, use: %i[finders slugged scoped], scope: :rebuild_id

  store_methods :topic_list, :topics_count, :author_list

  def slug_candidates
    custom_slug.blank? ? name : custom_slug
  end

  def should_generate_new_friendly_id?
    custom_slug_changed? || name_changed? || super
  end

  def author_list_without_links
    if authors.empty?
      '<strong>By</strong> BSSw Community'.html_safe
    else
      "<strong>By</strong> #{authors.map(&:display_name).to_sentence}
      ".html_safe
    end
  end

  def author_list
    if authors.empty?
      'BSSw Community'
    else
      authors.map do |auth|
        auth.link.html_safe
      end.to_sentence.html_safe
    end
  end

  

  
  scope :published, lambda {
    where(publish: true)
  }

  scope :with_topic, lambda { |topic|
    joins([:topics]).where('topics.id = ?', topic) if topic.present?
  }

  scope :with_category, lambda { |category|
    joins([:topics]).joins([:siteitems_topics]).where('topics.category_id = ?', category)
  }

  scope :with_author, lambda { |author|
    joins([:contributions]).where('contributions.author_id = ?', author.id)
  }

  scope :events, lambda {
    where(type: 'Event')
  }

  scope :blog, lambda {
    where(type: 'BlogPost').order('published_at desc')
  }

  scope :rss, lambda {
    where.not(rss_date: nil).or(
      where.not(published_at: nil).where(
        'published_at > ?', Chronic.parse('June 1 2018').to_s
      )
    ).order('rss_date desc', 'published_at desc').first(10)
  }

  scope :standard_scope, lambda { |_all = false|
    distinct.order(Arel.sql('(case when pinned then 1 else 0 end) DESC, name ASC'))
  }

  def topic_list
    topics.map(&:name).join(', ')
  end

  # scope :get, lambda { |options|
  #   result = self
  #   options.each do |key, val|
  #     result = result.send("with_#{key}", val) if val
  #   end
  #   result
  # }

  def basic?
    is_a?(WhatIs) || is_a?(HowTo)
  end

  def add_topics(names)
    names.each do |top_name|
      next if top_name.blank?

      topic = Topic.from_name(top_name, rebuild_id)
      topics << topic if topic
    end
  end

  def rss_date
    super || published_at
  end

  def categories
    topics.map(&:category).uniq
  end

  def self.clean
    items = where(name: nil)
    items.each(&:delete)
    displayed.each do |si|
      si.refresh_topic_list
      si.refresh_author_list
    end
  end
end
