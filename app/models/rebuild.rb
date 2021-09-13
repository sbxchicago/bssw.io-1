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
      resource = GithubImporter.process_path(file.full_name, file.read, id)
      update_attribute(:files_processed, "#{files_processed}<li>#{resource.try(:path)}</li>")
    rescue StandardError => e
      puts e.inspect
      record_errors(file_name, e)
    end
  end

  def record_errors(file_name, error)
    update_attribute(:errors_encountered,
                     "#{errors_encountered}
                       <h4>#{file_name}:</h4>
                       <h5>#{error}</h5> #{error.backtrace.first(10).join('<br />')}<hr />")
  end

  def clean
    Category.displayed.each { |category| category.update(slug: nil) }
    SiteItem.clean
    Fellow.displayed.each(&:set_search_text)
    SiteItem.displayed.each do |si|
      si.refresh_topic_list
      si.refresh_author_list
    end
  end
end
