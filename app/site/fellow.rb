# frozen_string_literal: true

# bios etc for fellows
class Fellow < MarkdownImport
  scope :displayed, lambda {
    where("#{table_name}.rebuild_id = ?", RebuildStatus.first.display_rebuild_id)
  }

  self.table_name = 'fellows'

  has_many :fellow_links

  after_create :set_hm

  extend FriendlyId

  friendly_id :name, use: %i[finders slugged scoped], scope: %i[rebuild_id honorable_mention]

  def self.perform_search(words)
    results = Fellow.displayed.where(honorable_mention: [nil, false])
    results = Searchable.get_word_results(words, results)
    words.flatten.uniq.each do |str_var|
      str_var = Regexp.escape(sanitize_sql_like(str_var))
      results = results.order(Arel.sql("name REGEXP \"#{Regexp.escape(str_var)}\" DESC"))
    end
    results
  end

  def should_generate_new_friendly_id?
    name_changed?
  end

  def set_search_text
    self.search_text = ActionController::Base.helpers.strip_tags("#{name} #{short_bio} #{long_bio}")
    save
  end

  def last_name
    name.try(:split).try(:last).to_s
  end

  def set_hm
    update_attribute(:honorable_mention, base_path.to_s.match?('HM'))
  end

  def modified_path
    MarkdownUtility.modified_path(image_path)
  end

  def update_from_content(doc, _rebuild)
    fellow_links.each(&:destroy)
    save
    update_details(doc)
  end

  def update_details(doc)
    doc.css('a.link-row').each do |link|
      FellowLink.create(url: link['href'], text: link.content, fellow_id: id)
      link.try(:remove)
    end
    do_fields(doc)
    node = doc.at("strong:contains('Long Bio')")
    node.try(:remove)
    send('long_bio=', doc.to_html)
    save
  end

  private

  def fields
    { 'Short Bio' => 'short_bio',
      'Year' => 'year',
      'Name' => 'name',
      'Affiliation' => 'affiliation',
      'Image' => 'image_path',
      'URL' => 'url',
      'LinkedIn' => 'linked_in',
      'Github' => 'github' }
  end

  def do_fields(doc)
    fields.each do |name, meth|
      node = doc.at("strong:contains('#{name}')")
      par = node.try(:parent)
      node.try(:remove)
      fix_italics(par)
      send("#{meth}=", par.try(:content))
      par.try(:remove)
      save
    end
  end

  def fix_italics(par)
    return unless par.respond_to?(:children)

    par.children.each do |p|
      p.replace("\_#{p.text}\_") if p.name == 'em'
    end
  end
end
