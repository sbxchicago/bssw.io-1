# frozen_string_literal: true

# resources, events, and blog posts
class SiteItem < GithubImport
  has_and_belongs_to_many :topics, -> { distinct } # , before_add: :inc_topic_count, before_remove: :dec_topic_count
  has_many :contributions, dependent: :destroy
  has_many :authors, through: :contributions
  has_and_belongs_to_many :communities, through: :features, class_name: 'Resource'

  has_many :features

  validates_uniqueness_of :path, optional: true, case_sensitive: false, scope: :rebuild_id
  has_many :announcements

  before_save :set_search_text

  extend FriendlyId
  friendly_id :slug_candidates, use: %i[finders slugged scoped], scope: :rebuild_id

  store_methods :topic_list, :topics_count

  def slug_candidates
    if custom_slug.blank? || custom_slug.nil?
      name
    else
      custom_slug
    end
  end

  def should_generate_new_friendly_id?
    custom_slug_changed? || name_changed? || super
  end

  def author_list_without_links
    if authors.empty?
      '<strong>By</strong> BSSw Community'.html_safe
    else
      '<strong>By</strong> ' +  authors.map do |auth|
        "#{auth.first_name} #{auth.last_name}"
      end.to_sentence.html_safe
    end
  end

  def author_list
    if authors.empty?
      'BSSw Community'
    else
      authors.map do |auth|
        "<a class='author' href='/items?author=#{auth.slug}'>#{auth.first_name} #{auth.last_name}</a>".html_safe
      end.to_sentence.html_safe
    end
  end

  scope :past, lambda {
    where(
      'end_at < ?', Date.today
    ).order('start_at DESC')
  }
  scope :upcoming, lambda {
    where('end_at >= ?', Date.today).order('start_at ASC')
  }

  scope :published, lambda {
    where(publish: true)
  }

  scope :preview, lambda {
    where(preview: true).or(where(publish: true))
  }

  scope :with_topic, lambda { |topic|
    joins(:topics).where('topics.id = ?', topic) if topic.present?
  }

  scope :with_category, lambda { |category|
    joins(:topics).where('topics.category_id = ?', category)
  }

  scope :with_author, lambda { |author|
    joins(:contributions).where('contributions.author_id = ?', author.id)
  }

  # scope :resources, lambda {
  #   where(type: 'Resource')
  # }

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

  scope :get, lambda { |options|
    result = self
    options.each do |key, val|
      result = result.send("with_#{key}", val) if val
      p
    end
    result
  }

  has_many :events,
           class_name: 'SiteItem', through: :event_resources, foreign_key: :event_id, primary_key: :resource_id

  # has_many :subresource_relations,
  #          foreign_key: :parent_resource_id
  # has_many :subresources, class_name: 'SiteItem', through: :subresource_relations, foreign_key: :subresource_id,
  #                         primary_key: :parent_resource_id
  # has_many :parent_resources, class_name: 'SiteItem', through: :subresource_relations,
  #                             foreign_key: :parent_resource_id, primary_key: :subresource_id

  has_and_belongs_to_many :children, lambda {
    distinct
  },
                          join_table: 'children_parents',
                          class_name: 'SiteItem',
                          foreign_key: 'child_id',
                          association_foreign_key: 'parent_id'
  has_and_belongs_to_many :parents, lambda {
    distinct
  },
                          join_table: 'children_parents',
                          class_name: 'SiteItem',
                          foreign_key: 'parent_id',
                          association_foreign_key: 'child_id'

  def basic?
    is_a?(WhatIs) || is_a?(HowTo)
  end

  def self.prepare_strings(string)
    if string.match(Regexp.new('"[^"]*"'))
      [[string.gsub(
        '"', ''
      )]]
    elsif string.match(Regexp.new("'[^']*'"))
      [[string.gsub(
        "'", ''
      )]]
    else
      lem = Lemmatizer.new
      string.split(' ').map do |str|
        [
          str, lem.lemma(str), str.stem
        ].uniq
      end
    end
    #    strings
  end

  def self.order_results(words, results)
    word_array = []
    words.flatten.uniq.each do |str_var|
      unless str_var.blank?
        str_var = Regexp.escape(sanitize_sql_like(str_var))
        word_array << "name REGEXP \"#{Regexp.escape((str_var))}\" DESC"
      end
    end
    results.order(Arel.sql("field (type, 'WhatIs', 'HowTo', 'Resource', 'BlogPost', 'Event') ASC, #{word_array.join(',')}"))
  end

  def self.perform_search(words, page, preview)
    o_results = if preview
                  SiteItem.preview.displayed
                else
                  SiteItem.published.displayed
                end
    results = o_results
    results = get_word_results(
      words, results
    )
    results = order_results(
      words, results
    )
    Fellow.perform_search(
      words, page
    ) + results
  end

  def self.get_word_results(words, results)
    word_results = nil
    words.each do |word|
      word.flatten.uniq.each do |str_var|
        str_var = Regexp.escape(sanitize_sql_like(str_var))
        str = "search_text REGEXP \"([\\W]*|^)#{str_var}\" or search_text REGEXP \"#{str_var}([\\W]*|$)\""
        relation = results.where(Arel.sql(str))
        word_results = word_results ? word_results.or(relation) : relation
      end
      results = results.merge(word_results)
    end
    results
  end

  def set_search_text
    self.search_text =
      ActionController::Base.helpers.strip_tags(
        "#{content} #{try(:author_list)} #{name} #{try(:description)} #{try(:location)} #{try(:organizers)}"
      )
    true
  end

  def update_from_content(doc, rebuild_id)
    update_author(
      doc.at("h4:contains('Contributed')"), rebuild_id
    )
    # header = doc.at("p:contains('Subresources:')")
    # if header
    #   subresource_content(
    #     header, doc, rebuild_id
    #   )
    # end
    super(doc, rebuild_id)
  end

  def add_topics(names, rebuild)
    names.each do |top_name|
      next if top_name.match(Regexp.new(/\[(.*)\]/))

      name = top_name.strip
      top = Topic.find_or_create_by(
        name: name.titleize,
        rebuild_id: rebuild
      )
      top.slug = name.parameterize
      topics << top
    end
  end

  def rss_date
    super || published_at
  end

  def update_author(node, rebuild)
    return unless node

    authors = Author.make_from_data(
      node, rebuild
    )
    self.authors = authors
    node.try(:remove)
  end

  def categories
    topics.map(&:category).uniq
  end

  # def add_to_parent(res, doc, header)
  #   res.update_taxonomy_from_child(self)
  #   return unless content

  #   h3 = Nokogiri::XML::Node.new(
  #     'h3', doc
  #   )
  #   h3.content = name
  #   header.before h3
  #   new_node = Nokogiri::HTML(content).at('body')
  #   header.before new_node.inner_html if new_node
  # end

  # def update_taxonomy_from_child(child)
  #   self.topics = topics + child.topics
  # end

  def basics
    topics.map(&:basics).flatten.uniq
  end

  def topics_count
    topics.size
  end

  # private

  # def subresource_content(header, doc, rebuild)
  #   subrs = header.next_element
  #   return unless subrs

  #   create_subresources(
  #     subrs, doc, header, rebuild
  #   )
  # end

  # def create_subresources(subrs, doc, header, rebuild)
  #   subrs.css('a').each do |subr|
  #     create_subresource(
  #       subr, rebuild
  #     )
  #     subr.parent.try(:remove)
  #   end
  #   header.content = ''
  #   subresources.each do |subr|
  #     subr.add_to_parent(
  #       self, doc, header
  #     )
  #   end
  # end

  # def create_subresource(subr, rebuild)
  #   con = subr.attr('href')
  #   res = SiteItem.find_or_create_by(
  #     path: File.basename(con), rebuild_id: rebuild
  #   )
  #   SubresourceRelation.create(
  #     order: subresource_relations.map(&:order).max || 0 + 1,
  #     parent_resource: self,
  #     subresource: res
  #   )
  # end

  def self.clean
    items = where(name: nil)

    items.each(&:delete)
    all.each do |si|
      si.refresh_topic_list
      #      si.refresh_author_list
      si.refresh_topics_count
    end
  end
end
