# frozen_string_literal: true

# created each time we run the GH import
class Rebuild < ApplicationRecord
  default_scope { order(created_at: 'desc') }
  after_create :set_location

  def set_location
    update_attribute(
      :location,
      Geocoder.search(ip).try(:first).try(:data).try(:[], 'city')
    )
  end

  def self.in_progress
    !(Rebuild.where('started_at > ?', 10.minutes.ago).to_a.select { |rebuild| rebuild.ended_at.blank? }).empty?
  end

  def process_file(file)
    full_name = file.full_name
    begin
      resource = process_path(full_name, file.read)
      update_attribute(:files_processed, "#{files_processed}<li>#{resource.try(:path)}</li>")
    rescue Exception => e
      record_errors(File.basename(full_name), e)
    end
  end

  def record_errors(file_name, error)
    update_attribute(:errors_encountered,
                     "#{errors_encountered}
                       <h4>#{file_name}:</h4>
                       <h5>#{error}</h5> #{error.backtrace.join('<br />')}<hr />")
  end

  def update_links_and_images
    (Page.all + SearchResult.all + Community.all
    ).each(&:update_links_and_images)
  end

  def clean(file_path)
    Category.displayed.each { |category| category.update(slug: nil) }
    AuthorUtility.all_custom_info(id, file_path)
    clear_old
    update_links_and_images
    begin
      Author.all.each(&:cleanup)
    rescue
    end
    SearchResult.clear_index!
    SearchResult.displayed.reindex
    # Fellow.all.each(&:set_search_text)
    # SiteItem.all.each(&:set_search_text)
    File.delete(file_path)
  end

  def clear_old
    rebuild_ids = Rebuild.first(5).to_a.map(&:id).delete_if(&:nil?)
    rebuild_ids += [id]
    classes = [Community, Category, Topic, Announcement, Author, Quote, SearchResult, FeaturedPost, Fellow, Page]
    everything = Rebuild.where(['id NOT IN (?)', rebuild_ids])
    classes.each do |klass|
      everything += klass.where(['rebuild_id NOT IN (?)', rebuild_ids])
      everything += klass.where(rebuild_id: nil)
    end

    everything.each(&:destroy)
  end

  def self.file_structure # rubocop:disable Metrics/MethodLength
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
    }
  end

  def process_path(path, content)
    return if path.match('utils/') || path.match('test/') || path.match('docs/') || content.nil?

    if path.match('Quote')
      Quote.import(content)
    elsif path.match('Announcements')
      Announcement.import(content, id)
    else
      resource = find_or_create_resource(path)
      resource.parse_and_update(content)
      resource
    end
  end

  def find_or_create_resource(path)
    res = Page
    Rebuild.file_structure.each do |expression, class_name|
      if path.match(Regexp.new(expression))
        res = class_name
        break
      end
    end
    item = res.find_or_create_by(path: GithubImporter.normalized_path(path), rebuild_id: self.id)
    item.update(base_path: File.basename(path))
    item
  end
end
