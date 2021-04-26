# frozen_string_literal: true

# plain content
class Page < GithubImport
  scope :displayed, lambda {
    where("#{table_name}.rebuild_id = ?", RebuildStatus.first.display_rebuild_id)
  }

  validates_presence_of :path, :name
  validates_uniqueness_of :path, case_sensitive: false, scope: :rebuild_id
  scope :published, -> { where(publish: true) }

  self.table_name = 'pages'

  extend FriendlyId

  friendly_id :name, use: %i[finders history slugged scoped], scope: :rebuild_id

  def regular
    name != 'Contact BSSw' &&
      name != 'Resources' &&
      name != 'Upcoming Events' &&
      name != 'Past Events'
  end

  def home?
    slug == 'homepage'
  end

  def update_from_content(doc, rebuild)
    self.slug = nil
    update_featured(doc)
    update_staff(doc, rebuild) if path.match('About')
    super(doc, rebuild)
    self.slug = 'homepage' if path.match('Home')
    save
  end

  def self.names_to_pages(names)
    names.map do |name|
      find_by(name: name, rebuild_id: RebuildStatus.first.display_rebuild_id)
    end.delete_if(&:!)
  end

  def self.orientation
    names_to_pages(['Communities Overview',
                    'Intro To CSE',
                    'Intro To HPC'])
  end

  def self.fellows
    names_to_pages(['BSSw Fellowship Program',
                    'Apply for the BSSw Fellowship Program',
                    'Meet Our Fellows',
                    'BSSw Fellowship FAQ'])
  end

  def self.contribute
    names_to_pages(
      ['What To Contribute: Content for Better Scientific Software',
       'How To Contribute Content to Better Scientific Software',
       'Questions About Contributing to Better Scientific Software?']
    )
  end

  private

  def update_staff(doc, rebuild)
    start_node = doc.css('h2')[0]
    return unless start_node

    node = start_node.next_element
    while node
      break if doc.css('h2').index(node)

      update_staffers(doc, node, rebuild) if doc.css('h3').index(node)
      old_node = node
      node = old_node.next_element
      old_node.remove
    end
  end

  def update_staffers(doc, node, rebuild)
    # node = doc.at("h3:contains('#{val}')")
    # return unless node
    val = node.text
    node = node.next_element

    while node
      break if doc.css('h2').index(node)
      break if doc.css('h3').index(node)

      Staff.make_from_data(node, val, rebuild)
      old_node = node
      node = old_node.next_element
      old_node.remove
    end
  end

  def update_featured(doc)
    node = doc.at("//comment()[contains(.,'Slide1')]")
    return unless node

    node.text.split("\n").map do |slide|
      slide_info = slide.split(':')
      path = slide_info.last
      FeaturedPost.create(path: path, label: slide_info.first, rebuild_id: rebuild_id) unless path == '-'
    end
    node.remove
  end
end
