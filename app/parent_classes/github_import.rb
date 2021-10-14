# frozen_string_literal: true

# methods that apply to all the stuff imorted from gh...
class GithubImport < ApplicationRecord
  self.abstract_class = true

  belongs_to :rebuild

  def parse_and_update(content)
    doc = GithubImporter.parse_html_from(content)
    update_from_content(doc, rebuild)
    self
  end

  def update_from_content(doc, rebuild)
    title_chunk = MarkdownUtility.get_title_chunk(doc)
    res = find_from_title(title_chunk)
    res.dates(doc, rebuild)
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

  def update_author(node, rebuild)
    return unless node && respond_to?('authors')

    auths = AuthorUtility.make_from_data(
      node, rebuild
    )
    self.authors = auths
    node.try(:remove)
  end
end
