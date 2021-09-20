# frozen_string_literal: true

# utility methods for the import
class GithubImporter < ApplicationRecord
  self.abstract_class = true

  def self.excluded_filenames
    ['README.md', 'LICENSE', '.gitignore', 'Abbreviations.md', 'CODE_OF_CONDUCT.md', 'CONTRIBUTING.md', 'index.md']
  end

  def self.parse_html_from(updated_content)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
                                       autolink: true,
                                       tables: true,
                                       lax_spacing: true,
                                       disable_indented_code_blocks: true,
                                       fenced_code_blocks: true)
    Nokogiri::HTML(markdown.render(updated_content), nil, 'UTF-8')
  end


  def self.normalized_path(path)
    new_path = path.split('/')
    new_path.shift
    new_path.join('/')
  end

  def self.github
    Octokit::Client.new(access_token: Rails.application.credentials[:github][:token])
  end

  def self.agent
    agent = Mechanize.new
    agent.pluggable_parser.default = Mechanize::Download
    agent
  end

  def self.tar_extract(file_path)
    tar = Gem::Package::TarReader.new(Zlib::GzipReader.open(file_path))
    tar.rewind
    tar
  end

  def self.get_title_chunk(doc)
    title_chunk = (doc.at_css('h1') || doc.at_css('h2') || doc.at_css('h3'))
    return unless title_chunk

    string = title_chunk.content.strip
    title_chunk.try(:remove)
    string
  end

  def self.custom_author_info(file_path)
    contrib_file = nil
    tar_extract(file_path).each do |file|
      contrib_file = file.read if file.header.name.match('Contributors.md')
    end
    Author.process_authors(rebuild.id)
    Author.process_overrides(parse_html_from(contrib_file), rebuild.id)
  end

  def self.populate
    cont = github.archive_link(Rails.application.credentials[:github][:repo],
                               ref: @branch)
    rebuild = RebuildStatus.in_progress_rebuild
    rebuild.update(content_branch: @branch)
    file_path = "#{Rails.root}/tmp/repo-#{@branch}.gz"
    agent.get(cont).save(file_path)
    tar_extract(file_path).each do |file|
      rebuild.process_file(file)
    end
    custom_author_info(file_path)
    File.delete(file_path)
    rebuild.update_links_and_images
  end
end
