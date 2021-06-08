# frozen_string_literal: true

# display and perform rebuilds
class RebuildsController < ApplicationController
  if Rails.env != 'preview'
    http_basic_authenticate_with name: Rails.application.credentials[:import][:name],
                                 password: Rails.application.credentials[:import][:password]
  end

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

  def update_links_and_images(build_id)
    (Page.where(rebuild_id: build_id) +
     SiteItem.where(rebuild_id: build_id) +
     Community.where(rebuild_id: build_id)
    ).each(&:update_links_and_images)
  end

  def populate_from_github(rebuild)
    branch = Rails.env.preview? ? 'preview' : 'master'

    cont = GithubImport.github.archive_link(Rails.application.credentials[:github][:repo],
                                            ref: branch)
    RebuildStatus.in_progress_rebuild.update(content_branch: branch)
    file_path = "#{Rails.root}/tmp/repo-#{branch}.gz"
    GithubImport.agent.get(cont).save(file_path)
    GithubImport.tar_extract(file_path).each do |file|
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
    clear_all
    rebuild.clean
    update_links_and_images(rebuild.id)
    RebuildStatus.complete(rebuild)
    Author.refresh_author_counts
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
