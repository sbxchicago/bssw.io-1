# frozen_string_literal: true

# process markdown into content for site
class MarkdownImport < GithubImport
  self.abstract_class = true

  scope :displayed, lambda {
    where("#{table_name}.rebuild_id = ?", RebuildStatus.first.display_rebuild_id)
  }

  
  def self.caption_regexp
    '\[(.*?)\]'
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

      link['href'] = MarkdownImport.update_link(href)
    end
  end

  def update_images(doc)
    doc.css('img').each do |img|
      MarkdownImport.update_image(img, doc)
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
    update_attribute(:open_graph_image_tag, MarkdownImport.modified_path(val))
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

  def self.add_caption(img)
    caption = img.parent.try(:content).try(:match, Regexp.new(caption_regexp))
    return unless caption

    span = Nokogiri::XML::Node.new 'span', img.document
    span['class'] = 'caption'
    span.content = caption[1]
    img.parent.children.each do |child|
      replace_caption(child, caption, span)
    end
  end

  def self.replace_caption(child, caption, span)
    return unless child.content.match?(Regexp.new(Regexp.escape(caption.to_s)))

    child.replace(
      child.content.gsub(Regexp.new(Regexp.escape(caption.to_s)), span.to_xml.html_safe)
    )
  end

  def self.add_lightbox(img, src)
    new_size = 'w_1366,h_768,c_fit'
    big_src = "https://res.cloudinary.com/bssw/image/fetch/#{new_size}/#{src}"
    link = Nokogiri::XML::Node.new 'a', img.document
    link['href'] = big_src
    link['data-toggle'] = 'lightbox'
    link.inner_html = img.to_xml.html_safe
    img.replace(link)
  end

  def self.update_image(img, _doc)
    class_name = img['class'].to_s
    src = modified_path(img['src'])
    img['src'] = "#{image_classes(class_name)}#{src}" # adjusted_src
    add_caption(img)
    add_lightbox(img, src) if class_name.match('lightbox') # lb
  end

  def self.modified_path(image_path)
    if image_path.match?('http')
      "#{image_path.strip}?raw=true"
    elsif image_path
      branch = Rails.env.preview? ? 'preview' : 'master'
      path = URI(image_path.strip).path.split('/').select do |m|
        !m.empty? && !m.in?(['images', '.', '..'])
      end.join('/')
      "https://raw.githubusercontent.com/betterscientificsoftware/bssw.io/#{branch}/images/#{path}?raw=true"
    end
  end

  def self.update_link(path)
    route = Rails.application.routes.url_helpers
    [SiteItem, Page, Community].each do |klass|
      item = klass.displayed.where(base_path: path).first
      return route.send("#{klass.name.underscore}_path", item) if item.try(:id)
    end
    path
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
end
