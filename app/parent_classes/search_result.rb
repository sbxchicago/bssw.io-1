class SearchResult < MarkdownImport

  include AlgoliaSearch

  algoliasearch per_environment: true, sanitize: true, auto_index: false, if: :searchable? do
    # the list of attributes sent to Algolia's API
    attribute :name
    [:description, :short_bio, :long_bio, :author_list, :location, :organizers, :content].each do |facet|
      attribute facet do
        respond_to?(facet) ? self.send(facet) : nil
      end
      ranking ['custom', 'typo', 'geo', 'words', 'filters', 'proximity', 'attribute', 'exact' ]
      customRanking ['desc(is_person)', 'desc(published_at)']
      advancedSyntax true
    end

  end

  extend FriendlyId
  friendly_id :slug_candidates, use: %i[finders slugged scoped], scope: :rebuild_id

  def slug_candidates
    custom_slug.blank? ? name : custom_slug
  end

  def should_generate_new_friendly_id?
    custom_slug_changed? || name_changed? || super
  end

  def searchable?
    publish && rebuild_id == RebuildStatus.first.display_rebuild_id
  end
  
  scope :published, lambda {
    where(publish: true)
  }

  scope :with_topic, lambda { |topic|
    joins([:topics]).where('topics.id = ?', topic) if topic.present?
  }


  scope :with_category, lambda { |category|
    joins([:topics]).joins([:searchresults_topics]).where('topics.category_id = ?', category)
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
    ).order(Arel.sql('coalesce(rss_date, published_at) desc')).first(15)
  }

  scope :standard_scope, lambda { |_all = false|
    distinct.order(Arel.sql('(case when pinned then 1 else 0 end) DESC, name ASC'))
  }


  has_and_belongs_to_many :topics, -> { distinct }, join_table: 'site_items_topics', dependent: :destroy, foreign_key: 'site_item_id'
  before_destroy { topics.clear }
  before_destroy { contributions.clear }
  has_many :contributions,  join_table: 'contributions', dependent: :destroy, foreign_key: 'site_item_id'
  has_many :authors, through: :contributions


  has_many :features, foreign_key: 'site_item_id'

  validates :path,  uniqueness: { case_sensitive: false, scope: :rebuild_id, allow_blank: true }

  has_many :announcements, foreign_key: 'site_item_id'


  store_methods :topic_list, :topics_count, :author_list



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
      authors.map { |a| a.link.html_safe }.to_sentence.html_safe
    end
  end


  def topic_list
    topics.map(&:name).join(', ')
  end

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


  
end
