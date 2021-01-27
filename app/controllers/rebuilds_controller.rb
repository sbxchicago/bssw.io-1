# frozen_string_literal: true

# display and perform rebuilds
class RebuildsController < ApplicationController
  http_basic_authenticate_with name: Rails.application.credentials[:import][:name], password: Rails.application.credentials[:import][:password]  if Rails.env != 'preview'
  before_action :check_rebuilds, only: ['import']

  def index
    @rebuilds = Rebuild.all
  end

  def make_displayed
    rs = RebuildStatus.first
    rs.update_attribute(:display_rebuild_id, params[:id])
    flash[:notice] = 'Reverted!'
    redirect_to '/rebuilds'
  end

  def update_links_and_images
    (Page.displayed + SiteItem.displayed + Community.displayed).each(&:update_links_and_images)
  end

  def populate_from_github(rebuild)
    cont = GithubImport.github.archive_link(Rails.application.credentials[:github][:repo], ref: Rails.env.preview? ? 'preview' : 'master')
    file_path = "#{Rails.root}/tmp/repo.gz"
    GithubImport.agent.get(cont).save(file_path)
    tar_extract = GithubImport.tar_extract(file_path)
    tar_extract.each do |file|
      rebuild.process_file(file)
    end
    File.delete(file_path)
  end

  def clear_all
    rebuild_ids = Rebuild.first(5).to_a.map(&:id).delete_if(&:nil?)
    classes = [Community, Category, Topic, Announcement, Author, Quote, SiteItem, FeaturedPost, Fellow]
    everything = Rebuild.where(['id NOT IN (?)', rebuild_ids])
    classes.each do |klass|
      everything += klass.where(['rebuild_id NOT IN (?)', rebuild_ids])
      everything += klass.where(rebuild_id: nil)
    end
    everything.each(&:delete)
  end

  def import
    rebuild = Rebuild.create(started_at: Time.now, ip: request.ip)
    RebuildStatus.start(rebuild)
    populate_from_github(rebuild)

    RebuildStatus.complete(rebuild)

    update_links_and_images
    clear_all
    rebuild.clean
    puts rebuild.errors_encountered
    flash[:notice] = 'Import completed!'
    redirect_to controller: 'rebuilds', action: 'index', rebuilt: true
  end

  def check_rebuilds
    return unless Rebuild.in_progress

    flash[:error] =
      'Another rebuild (started less than 10 minutes ago) is in progress.
        Please wait for this rebuild to complete, or wait 10 minutes to override.'
    redirect_to controller: 'rebuilds', action: 'index'
  end
end
