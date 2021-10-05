# frozen_string_literal: true

# process markdown into content for site
class MarkdownImport < GithubImport
  self.abstract_class = true

  scope :displayed, lambda {
    where("#{table_name}.rebuild_id = ?", RebuildStatus.first.display_rebuild_id)
  }

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

      link['href'] = MarkdownUtility.update_link(href)
    end
  end

  def update_images(doc)
    doc.css('img').each do |img|
      MarkdownUtility.update_image(img, doc)
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
        send(method, names.join)
      end
    end
  end

  def add_opengraph_image(val)
    update_attribute(:open_graph_image_tag, MarkdownUtility.modified_path(val))
  end

  def add_rss_update(val)
    date = Chronic.parse(val)
    update_attribute(:rss_date, date)
  end

  def add_slug(val)
    self.custom_slug = val.downcase
    save
  end

  def add_aggregate(val)
    update_attribute(:aggregate, val) if has_attribute?(:aggregate)
  end

  def add_publish(val)
    val = val.downcase
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

  def update_date(doc)
    return unless respond_to?('published_at')

    node = doc.at("h4:contains('Publication date')")
    node ||= doc.at("h4:contains('Publication Date')")
    node ||= doc.at("h4:contains('publication date')")
    return unless node

    date = Chronic.parse(node.content.split(':').last)
    self.published_at = date
    node.try(:remove)
  end

  def dates(doc, rebuild)
    update_date(doc)
    return if !has_attribute?(:published_at) || is_a?(Event) || !published_at.blank?

    puts "using content branch #{rebuild.content_branch} to override publish date for #{path}"
    update_attribute(:published_at,
                     GithubImporter.github.commits(
                       Rails.application.credentials[:github][:repo],
                       rebuild.content_branch,
                       path: "/#{path}"
                     ).try(:first).try(:commit).try(:author).try(:date))
  end
end
