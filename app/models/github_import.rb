# frozen_string_literal: true

# methods that apply to all the stuff imorted from gh...
class GithubImport < ApplicationRecord
  self.abstract_class = true

  scope :displayed, lambda {
    where("#{table_name}.rebuild_id = ?", RebuildStatus.first.display_rebuild_id)
  }

  def self.excluded_filenames
    ['README.md', 'LICENSE', '.gitignore', 'Abbreviations.md', 'CODE_OF_CONDUCT.md', 'CONTRIBUTING.md', 'index.md',
     'StyleGuide.md']
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

  def parse_and_update(content, rebuild_id)
    doc = Resource.parse_html_from(content)
    update_from_content(doc, rebuild_id)
    self
  end

  def update_from_content(doc, rebuild_id)
    title_chunk = GithubImport.get_title_chunk(doc)
    res = find_from_title(title_chunk)
    if res.has_attribute?(:published_at)
      res.update_date(doc)
      do_dates(res) unless res.is_a?(Event) || !res.published_at.blank?
    end

    res.update_taxonomy(doc, rebuild_id)

    content_string = doc.css('body').to_s + "\n<!-- file: #{res.path} -->".html_safe
    res.update_attribute(:content, content_string)
  end

  def do_dates(res)
    gh_path = res.path.split('/')
    gh_path.shift
    gh_path = gh_path.join('/')
    res.update_attribute(:published_at,
                         GithubImport.github.commits(
                           Rails.application.credentials[:github][:repo],
                           RebuildStatus.content_branch,
                           path: gh_path
                         ).first.commit.author.date)
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

  def self.parse_html_from(updated_content)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
                                       autolink: true,
                                       tables: true,
                                       lax_spacing: true,
                                       disable_indented_code_blocks: true,
                                       fenced_code_blocks: true)
    Nokogiri::HTML(markdown.render(updated_content), nil, 'UTF-8')
  end

  def self.find_or_create_resource(path, rebuild_id)
    res = Page
    {
      'CuratedContent/WhatIs' => WhatIs,
      'CuratedContent/WhatAre' => WhatIs,
      'CuratedContent/HowTo' => HowTo,
      'Articles/WhatIs' => WhatIs,
      'Articles/WhatAre' => WhatIs,
      'Articles/HowTo' => HowTo,
      'Site/Topic' => Category,
      '/People/' => Fellow,
      'Site/Communities/..+.md' => Community,
      'Site/' => Page,
      'Events' => Event,
      'Blog/' => BlogPost,
      'Articles/' => Resource,
      'CuratedContent/' => Resource
    }.each do |expression, class_name|
      if path.match(Regexp.new(expression))
        res = class_name
        break
      end
    end
    res = Category if path.match('Site/Topics')
    item = res.find_or_create_by(base_path: File.basename(path), rebuild_id: rebuild_id)
    item.update(path: path)
    item
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

  def self.update_link(path)
    route = Rails.application.routes.url_helpers
    site_item = SiteItem.find_by_path(path)
    page = Page.find_by_path(path)
    community = Community.find_by_path(path)
    return route.site_item_path(site_item) if site_item.try(:id)
    return route.page_path(page) if page.try(:id)
    return route.community_path(community) if community.try(:id)
  end

  def self.image_classes(name)
    classes = {
      'header' => 'w_1600,h_585,c_fill',
      'logo' => 'w_200,h_200,c_fit/',
      'inline' => 'w_1008,h_567,c_fit',
      'portrait' => 'w_600,h_600,c_fill'
    }
    size = classes[name]
    "https://res.cloudinary.com/bssw/image/fetch/#{size}"
  end

  def self.update_image(img, _doc)
    class_name = img['class'].to_s
    src = modified_path(img['src'])
    img['src'] = "#{image_classes(class_name)}#{src}" # adjusted_src
    add_caption(img,  img.parent.try(:content).try(:match, Regexp.new('\[(.*?)\]'))) unless img.parent.nil?
    add_lightbox(img, src) if class_name.match('lightbox') # lb
  end

  def self.modified_path(image_path)
    image_path = image_path.strip
    if image_path.match?('http')
      "#{image_path}?raw=true"
    elsif image_path
      branch = Rails.env.preview? ? 'preview' : 'master'
      repo = 'betterscientificsoftware/bssw.io'
      "https://raw.githubusercontent.com/#{repo}/#{branch}/images/#{File.basename(image_path)}?raw=true"
    end
  end

  def self.add_caption(img, caption)
    return unless caption

    span = Nokogiri::XML::Node.new 'span', img.document
    span['class'] = 'caption'
    span.content = caption[1]
    par = img.parent
    return unless par

    cont = par.content
    par.content = cont.gsub(Regexp.new('\[.*?\]'), '')
    par << img
    par << span
  end

  def self.add_lightbox(img, src)
    new_size = 'w_1366,h_768,c_fit'
    big_src = "https://res.cloudinary.com/bssw/image/fetch/#{new_size}/#{src}"
    img.replace(
      "<a href='#{big_src}' data-toggle='lightbox'>#{img.to_xml}</a>"
    )
  end

  def self.process_path(path, content, rebuild)
    return if path.match('test/') || path.match('docs/') || content.nil?

    if path.match('Quote')
      Quote.import(content)
    elsif path.match('Announcements')
      Announcement.import(content, rebuild)
    else
      resource = find_or_create_resource(path, rebuild)
      resource.parse_and_update(content, rebuild)
      resource
    end
  end

  def update_links_and_images
    doc = Nokogiri::HTML.parse(content, nil, 'UTF-8')
    update_links(doc)
    update_images(doc)
    html = doc.to_html.to_s.force_encoding('UTF-8')
    update_attribute(:content, html) unless content == html
  end

  def update_taxonomy(doc, rebuild)
    comments = doc.xpath('//comment()') if doc
    comments&.each do |comment|
      array = comment.text.split(/:|\n/).collect do |val|
        val.strip || val
      end - ['-']
      update_associates(array, rebuild)
      comment.content = nil
    end
  end

  def update_links(doc)
    doc.css('a').each do |link|
      href = link['href']
      next unless href&.match('\.md$') && !href.match('^http')

      href = href.split('/').last

      link['href'] = Resource.update_link(href)
    end
  end

  def update_images(doc)
    doc.css('img').each do |img|
      GithubImport.update_image(img, doc)
    end
  end

  def update_associates(array, rebuild)
    array.each_cons(2) do |string, names|
      names = names.split(',')
      method = "add_#{string}".downcase.tr(' ', '_')
      if method == 'add_topics'
        save if new_record?
        try(:add_topics, names, rebuild)
      elsif respond_to?(method, true)
        send(method, names.join.downcase)
      end
    end
  end

  def add_rss_update(val)
    date = Chronic.parse(val)
    update_attribute(:rss_date, date)
  end

  def add_slug(val)
    self.custom_slug = val
    save
  end

  def add_aggregate(val)
    update_attribute(:aggregate, val) if has_attribute?(:aggregate)
  end

  def add_publish(val)
    if val.match('yes')
      update_attribute(:publish, true)
    else
      update_attribute(:publish, false)
    end
    update_attribute(:preview, true) if val.match('preview')
  end

  def add_pinned(val)
    update_attribute(:pinned, true) if val.downcase.match('y') && has_attribute?(:pinned)
  end

  def self.github
    Octokit::Client.new(access_token: Rails.application.credentials[:github][:token])
  end

  def self.get_title_chunk(doc)
    title_chunk = (doc.at_css('h1') || doc.at_css('h2') || doc.at_css('h3'))
    return unless title_chunk

    string = title_chunk.content.strip
    title_chunk.try(:remove)
    string
  end

  def find_from_title(string)
    res = self.class.find_by(name: string, rebuild_id: rebuild_id) || self
    res.name = string
    res.save
    res
  end
end
