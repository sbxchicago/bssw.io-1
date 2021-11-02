# frozen_string_literal: true

# utility methods for processing authors
class AuthorUtility
  def self.all_custom_info(rebuild_id, file_path)
    Fellow.where(rebuild_id: rebuild_id).each(&:set_search_text)
    Author.where(rebuild_id: rebuild_id).each(&:update_from_github)
    custom_staff_info(file_path, rebuild_id)
    custom_author_info(file_path, rebuild_id)
    Author.where(rebuild_id: rebuild_id).each(&:set_search_text)
  end

  # def self.process_authors(rebuild_id)
  # #   refresh_authors(rebuild_id)
  # end

#   def self.refresh_authors(rebuild_id)
#      puts "refreshing authors for #{rebuild_id}"
#      Author.all.each do |author|
#   #   #   author.refresh_counts
# #        author.refresh_listings
#       end
#    end

  def self.names_from(name)
    return [nil, nil] unless name.respond_to?(:split)
    return %w[BSSw Community] if name.match?(/BSSw Community/i)

    names = name.split(' ').map { |chunk| chunk.blank? ? nil : chunk }
    last_name = names.last
    first_name = [names - [last_name]].join(' ')
    [first_name, last_name]
  end

  def self.do_overrides(comment, rebuild)
    comment.text.split(/\n/).collect do |text|
      next if text.match?(/Overrides/i)

      vals = text.split(',').map { |val| val.delete('"') }
      alpha_name = vals.first
      display_name = vals.last
      author = Author.find_from_vals(alpha_name, display_name, rebuild)
      author&.do_overrides(alpha_name, display_name)
    end
  end

  def self.process_overrides(doc, rebuild)
    comments = doc.xpath('//comment()') if doc
    comments&.each do |comment|
      next unless comment.text.match?(/Overrides/i)

      do_overrides(comment, rebuild)
    end
  end

  def self.custom_author_info(file_path, rebuild_id)
    contrib_file = nil
    GithubImporter.tar_extract(file_path).each do |file|
      contrib_file = file.read if file.header.name.match('Contributors.md')
    end
    AuthorUtility.process_overrides(GithubImporter.parse_html_from(contrib_file), rebuild_id)
  end

  def self.custom_staff_info(file_path, rebuild_id)
    contrib_file = nil
    GithubImporter.tar_extract(file_path).each do |file|
      contrib_file = file.read if file.header.name.match('About.md')
    end
    Page.where(rebuild_id: rebuild_id, base_path: 'About.md').first.update_from_content(
      GithubImporter.parse_html_from(contrib_file), rebuild_id
    )
  end

  def self.make_from_data(node, rebuild)
    authors = []
    node.css('a').each do |link|
      authors << author_from_website(link, rebuild)
      link.remove
    end
    txt = node.text.gsub('Contributed by', '').gsub(' and ', ',').strip
    txt.split(',').each do |text|
      authors << author_from_text(text, rebuild)
    end
    authors.delete_if(&:nil?)
  end

  def self.author_from_text(text, rebuild)
    return if text.blank? || text.match?("\:") || text.match?("\#")

    names = names_from(text)
    auth = Author.find_or_create_by(rebuild_id: rebuild, last_name: names.last, first_name: names.first)
    auth.update(alphabetized_name: auth.last_name)
    auth
  end

  def self.author_from_website(link, rebuild)
    names = names_from(link.text)
    uri = URI.parse(link['href'])
    host = uri.host
    website = host.blank? ? nil : "https://#{host}#{uri.path}"

    auth = Author.find_by(website: website, rebuild_id: rebuild)
    unless auth
      last_name = names.last
      auth = Author.find_or_create_by(rebuild_id: rebuild, last_name: last_name, first_name: names.first)
      auth.update(website: website, alphabetized_name: last_name)
    end
    auth
  end
end
