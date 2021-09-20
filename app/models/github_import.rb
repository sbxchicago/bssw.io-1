# frozen_string_literal: true

# methods that apply to all the stuff imorted from gh...
class GithubImport < ApplicationRecord
  self.abstract_class = true

  scope :displayed, lambda {
    where("#{table_name}.rebuild_id = ?", RebuildStatus.first.display_rebuild_id)
  }

  def parse_and_update(content, rebuild)
    doc = GithubImporter.parse_html_from(content)
    update_from_content(doc, rebuild)
    self
  end

  def update_from_content(doc, rebuild)
    title_chunk = GithubImporter.get_title_chunk(doc)
    res = find_from_title(title_chunk)
    if res.has_attribute?(:published_at)
      res.update_date(doc)
      do_dates(res) unless res.is_a?(Event) || !res.published_at.blank?
    end
    update_author(doc.at("h4:contains('Contributed')"), rebuild_id)
    res.update_taxonomy(doc, rebuild)

    content_string = CGI.unescapeHTML(doc.css('body').to_s) + "\n<!-- file path: #{res.path} -->".html_safe
    res.update_attribute(:content, content_string)
  end

  def snippet
    pars = Nokogiri::HTML.parse(content, nil, 'UTF-8')
    pars.css('p').try(:first).to_s.html_safe
  end

  def main
    pars = Nokogiri::HTML.parse(content, nil, 'UTF-8')
    pars.css('p').try(:first).try(:remove)
    pars.to_s.html_safe
  end

  def find_from_title(string)
    res = self.class.find_by(name: string, rebuild_id: rebuild_id) || self
    res.name = string
    res.save
    res
  end

  def do_dates(res)
    res.update_attribute(:published_at,
                         GithubImporter.github.commits(
                           Rails.application.credentials[:github][:repo],
                           RebuildStatus.content_branch,
                           path: "/#{path}"
                         ).first.commit.author.date)
  end

  def update_author(node, rebuild)
    return unless node && respond_to?('authors')

    authors = Author.make_from_data(
      node, rebuild
    )
    self.authors = authors
    node.try(:remove)
  end

  def update_date(doc)
    node = doc.at("h4:contains('Publication date')")
    node ||= doc.at("h4:contains('Publication Date')")
    node ||= doc.at("h4:contains('publication date')")
    return unless node

    date = Chronic.parse(node.content.split(':').last)
    self.published_at = date
    node.try(:remove)
  end
end
