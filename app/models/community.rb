# frozen_string_literal: true

# a bss community
class Community < GithubImport
  validates_presence_of :path, :name

  scope :published, -> { where(publish: true) }
  default_scope { published }

  serialize :resource_paths, Array

  extend FriendlyId
  friendly_id :name, use: %i[finders slugged scoped], scope: :rebuild_id

  def resources
    resource_paths.map { |path| SiteItem.find_by_path(File.basename(path)) }.delete_if(&:nil?)
  end

  def update_from_content(doc, rebuild)
    save
    our_items = update_resources(doc) 
    super(doc, rebuild)
    our_items.each do |item|
      resource_paths << item
    end
    save
  end

  def update_resources(doc)
    our_links = []
    node = doc.xpath("//comment()[contains(.,'Featured resources')]").first

    while node
      node = node.next_element
      next unless node

      node.css('a').each do |link|
        href = link['href']
        our_links << href

        link.ancestors('li').first.try(:remove)
      end

      node.try(:remove)
    end
    our_links
  end
end
