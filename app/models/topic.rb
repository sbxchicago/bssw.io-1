# frozen_string_literal: true

# Filters - like tags
class Topic < GithubImport
  #  default_scope -> { order(order_num: 'asc') }
  self.table_name = 'topics'
  has_and_belongs_to_many :site_items, -> { distinct }
  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false, scope: :rebuild_id
  belongs_to :category, optional: true
  # after_save :update_resource_categories

  extend FriendlyId
  friendly_id :name, use: %i[finders history slugged scoped], scope: :rebuild_id

  #  after_create :set_slug

  # def update_resource_categories
  #   site_items.each {|res| res.categories << category if category; res.save }
  # end

  # def update_from_content(doc)
  #   super(doc)
  #   doc.at("") do |elem|
  #     Announcement.create_from(elem.next_element)
  #   end

  # end

  # def set_slug
  #    update_attribute(:slug, name.parameterize) if name
  # end

  def self.create_from_node(child, cat_id, rebuild_id)
    name = child.at('strong').content
    child.at('strong').remove
    topic = Topic.find_or_create_by(slug: name.parameterize, rebuild_id: rebuild_id)
    topic.update(overview: child.content, name: name, order_num: topic.get_order(child), category_id: cat_id)
    topic
  end

  def basics
    site_items.select(&:basic?)
  end

  def get_order(doc)
    comment = doc.at("//comment()[contains(.,'Topic order')]")
    return unless comment

    num = comment.text.match(/(\d+)/)
    comment.remove
    num.to_s.to_i
  end
end
