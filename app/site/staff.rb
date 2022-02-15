# frozen_string_literal: true

# to display on "about" page
class Staff < Author
  def self.make_from_data(node, val, rebuild)
    node.css('a').each do |link|
      auth = Author.find_or_create_by(website: link['href'], rebuild_id: rebuild)
      auth.update_attribute(:type, 'Staff')
      auth.update_attribute(:section, val)
      Staff.find(auth.id).update_from_link(link.parent.children)
    end
  end

  def process_kid(kid)
    text = kid.text
    kid.remove if text.blank? || kid.name == 'br'
    update_attribute(:title, text.gsub('Title: ', '')) if kid && text.match?('Title')
    kid.try(:remove)
  end

  def update_from_link(siblings)
    siblings.each do |kid|
      process_kid(kid)
    end
    names = AuthorUtility.names_from(siblings.first.text)
    update(first_name: names.first, last_name: names.last, alphabetized_name: names.last)
    update_affiliation(siblings)
  end

  def update_affiliation(siblings)
    if siblings[2].text.match('Title')
      update_attribute(:affiliation,
                       siblings[4].text.strip)
    else
      update_attribute(:affiliation,
                       siblings[2].text.strip)
    end
  end
end
