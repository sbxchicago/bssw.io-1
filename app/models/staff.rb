# frozen_string_literal: true

# to display on "about" page
class Staff < Author
  def self.make_from_data(node, val, rebuild)

    node.css('a').each do |link|
      auth = Author.find_or_create_by(website: link['href'], rebuild_id: rebuild)

      auth.update_attribute(:section, val)
      auth.update_attribute(:type, 'Staff')

      auth.update_from_link(link)
    end

  end
end
