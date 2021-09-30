# frozen_string_literal: true

# utility methods for processing authors
class AuthorUtility
  def self.process_authors(rebuild)
    puts "#{self.class.name} gets author info from github"
    Author.where(rebuild_id: rebuild).each(&:update_from_github)
    refresh_author_counts
  end

  def self.refresh_author_counts
    Author.displayed.each do |auth|
      auth.refresh_resource_count
      auth.refresh_event_count
      auth.refresh_blog_count
      auth.refresh_resource_listing
      auth.refresh_blog_listing
      auth.refresh_event_listing
    end
  end

  def self.names_from(name)
    return [nil, nil] unless name.respond_to?(:split)
    return %w[BSSw Community] if name.match?(/BSSw Community/i)

    names = name.split(' ')
    names = names.map { |n| n.blank? ? nil : n }
    last_name = names.last
    first_name = [names - [last_name]].join(' ')
    [first_name, last_name]
  end

  def self.do_overrides(comment, rebuild)

    comment.text.split(/\n/).collect do |val|
      next if val.match?(/Overrides/i)

      vals = val.split(',').map { |v| v.delete('"') }
      author = Author.find_from_vals(vals, rebuild)
      author.do_overrides(vals) if author
    end
  end

  def self.process_overrides(doc, rebuild)
    comments = doc.xpath('//comment()') if doc
    comments&.each do |comment|
      next unless comment.text.match?(/Overrides/i)

      do_overrides(comment, rebuild)
    end
  end

  def self.custom_author_info(file_path, rebuild)
    puts "#{self.class.name} looks at the Contributors.md file for overrides to authors' github info"
    contrib_file = nil
    GithubImporter.tar_extract(file_path).each do |file|
      contrib_file = file.read if file.header.name.match('Contributors.md')
    end
    AuthorUtility.process_overrides(GithubImporter.parse_html_from(contrib_file), rebuild.id)
  end


  def self.custom_staff_info(file_path, rebuild)
    puts "#{self.class.name} looks at the About.md file for overrides to authors' github info"
    contrib_file = nil
    GithubImporter.tar_extract(file_path).each do |file|
      contrib_file = file.read if file.header.name.match('About.md')
    end
    Page.where(rebuild_id: rebuild.id, base_path: 'About.md').first.update_from_content(GithubImporter.parse_html_from(contrib_file), rebuild.id)
  end

  
  def self.make_from_data(node, rebuild)
    begin
    authors = []
    node.css('a').each do |link|
      auth = author_from_website(link, rebuild)
      authors << auth unless auth.nil?
      link.remove
    end
    txt = node.text.gsub('Contributed by', '').gsub(' and ', ',').strip
    txt.split(',').each do |text|
      auth = author_from_text(text, rebuild)
      authors << auth unless auth.nil?
    end
    rescue Exception => e
      puts "#{self.class} encountered #{e}"
    end
    authors.delete_if {|a| a.nil? }
  end

  def self.author_from_text(text, rebuild)
    return if text.blank? || text.match?("\:") || text.match?("\#")

    names = names_from(text)
    auth = Author.find_or_create_by(rebuild_id: rebuild, last_name: names.last, first_name: names.first)
    auth.update(alphabetized_name: names.last)
    auth
  end

  def self.author_from_website(link, rebuild)
    names = names_from(link.text)
    uri = URI.parse(link['href'])
    website = uri.host.blank? ? nil : "https://#{uri.host}#{uri.path}"

    auth = Author.find_by(website: website, rebuild_id: rebuild)
    unless auth
      auth = Author.find_or_create_by(rebuild_id: rebuild, last_name: names.last, first_name: names.first)
      auth.update(website: website, alphabetized_name: names.last)
    end
    auth
  end
end
