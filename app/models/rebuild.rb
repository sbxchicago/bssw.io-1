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
    !(Rebuild.where('started_at > ?', 10.minutes.ago).to_a.select { |r| r.ended_at.blank? }).empty?
  end

  def process_file(file)
    return if File.extname(file.full_name) != '.md'

    file_name = File.basename(file.full_name)
    return if GithubImporter.excluded_filenames.include?(file_name)

    begin
      resource = process_path(file.full_name, file.read)
      update_attribute(:files_processed, "#{files_processed}<li>#{resource.try(:path)}</li>")
    rescue StandardError => e
      record_errors(file_name, e)
    end
  end

  def process_path(path, content)
    return if path.match('utils/') || path.match('test/') || path.match('docs/') || content.nil?

    if path.match('Quote')
      Quote.import(content)
    elsif path.match('Announcements')
      Announcement.import(content, self.id)
    else
      resource = self.find_or_create_resource(path)
      resource.parse_and_update(content, self)
    end
  end

  def record_errors(file_name, error)
    update_attribute(:errors_encountered,
                     "#{errors_encountered}
                       <h4>#{file_name}:</h4>
                       <h5>#{error}</h5> #{error.backtrace.join('<br />')}<hr />")
  end

  def update_links_and_images
    (Page.where(rebuild_id: id) +
     SiteItem.where(rebuild_id: id) +
     Community.where(rebuild_id: id)
    ).each(&:update_links_and_images)
  end

  def clean
    SiteItem.clean
    RebuildStatus.complete(self)
    Category.displayed.each { |category| category.update(slug: nil) }
    Fellow.displayed.each(&:set_search_text)
    SiteItem.displayed.each do |si|
      si.refresh_topic_list
      si.refresh_author_list
    end
    Author.process_authors(self)

    Author.refresh_author_counts
    clear_old
  end
  
  def clear_old
    rebuild_ids = Rebuild.last(5).to_a.map(&:id).delete_if(&:nil?)
    rebuild_ids = rebuild_ids + [self.id]
    classes = [Community, Category, Topic, Announcement, Author, Quote, SiteItem, FeaturedPost, Fellow]
    everything = Rebuild.where(['id NOT IN (?)', rebuild_ids])
    classes.each do |klass|
      everything += klass.where(['rebuild_id NOT IN (?)', rebuild_ids])
      everything += klass.where(rebuild_id: nil)
    end
    everything.each(&:delete)
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

  def find_or_create_resource(path)
    res = Page
    Rebuild.file_structure.each do |expression, class_name|
      if path.match(Regexp.new(expression))
        res = class_name
        break
      end
    end
    item = res.find_or_create_by(base_path: File.basename(path), rebuild_id: self.id)
    item.update(path: GithubImporter.normalized_path(path))
    item
  end

  
end
