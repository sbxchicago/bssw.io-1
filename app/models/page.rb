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
    update_staff(doc, rebuild)
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
                    'Site Overview',
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
    update_staffers(doc, 'Associate', rebuild)
    update_staffers(doc, 'Senior', rebuild)
  end

  def update_staffers(doc, val, rebuild)
    node = doc.at("h2:contains('#{val}')")
    return unless node

    node = node.next_element

    while node
      Staff.make_from_data(node, val, rebuild)
      old_node = node
      node = old_node.next_element
      old_node.remove
    end
  end

  def update_featured(doc)
    node = doc.at("//comment()[contains(.,'Slide1')]")
    return unless node

    slides = node.text.split("\n").map do |slide|
      slide_info = slide.split(':')
      [slide_info.first, slide_info.last]
    end
    slides.each do |slide|
      path = slide.last
      FeaturedPost.create(path: path, label: slide.first, rebuild_id: rebuild_id) unless path == '-'
    end
    node.remove
  end
end
