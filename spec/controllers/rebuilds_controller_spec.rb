# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RebuildsController, type: :controller do
  before(:all) do
    @min_site_item_count = 100
    @community_count = 6
    @topic_slug = 'revision-control'
    @how_to_name = 'How to do Version Control with Git in your CSE Project'
    @what_is_slug = 'what-is-revision-control'
    @category_name = 'Better Development'
    @blog_post_slug = 'improve-user-confidence-in-your-software-updates'
    @author_slug = 'curfman'
    @search_expectations = { 'integration testing' => 57,
                             'testing' => 80,
                             'elaine' => 10,
                             'riley' => 1,
                             'c++' => 1 }
  end

  describe 'post import' do
    it 'tracks '
    it 'does some imports' do
      name = Rails.application.credentials[:import][:name]
      pw = Rails.application.credentials[:import][:password]
      @request.env['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64("#{name}:#{pw}")}"
      FactoryBot.create(:site_item)
      FactoryBot.create(:author)
      post :import

      # these are specific checks to our resource library...
      # using variables defined at top of this file
      expect(SiteItem.count).to be > @min_site_item_count
      expect(SiteItem.displayed.count).to be > @min_site_item_count
      expect(Community.displayed.count).to eq @community_count

      expect(Community.first.resources).not_to be_empty
      topic = Topic.displayed.where(slug: @topic_slug).first
      wi = SiteItem.displayed.find(@what_is_slug)
      expect(wi.topics).to include topic
      expect(topic.site_items).to include wi
      expect(topic.site_items).to include HowTo.displayed.find_by_name(@how_to_name)
      expect(topic.category).to eq Category.displayed.find_by_name(
        @category_name
      )

      expect(Fellow.all).not_to be_empty
      expect(Fellow.all.map(&:fellow_links).flatten).not_to be_empty
      expect(Fellow.all.map(&:honorable_mention).flatten.include?(true)).to be true
      expect(Fellow.first.name).not_to be_blank
      expect(Fellow.first.long_bio).not_to be_blank

      expect(BlogPost.find_by_slug(@blog_post_slug)).to be_a BlogPost

      expect(Quote.all).not_to be_empty
      expect(Announcement.all).not_to be_empty
      Announcement.all.each do |a|
        expect(a.site_item).not_to be_nil
      end
      expect(Page.find('homepage')).to be_a Page
      expect(Page.last.snippet).not_to be_empty
      expect(Author.displayed.where(website: @author_slug).size).to eq 1

      expect(Author.displayed.where(website: @author_slug).first.resource_listing).not_to eq '0 resources'
      expect(Staff.displayed.where(website: 'maherou').first.affiliation).to eq 'Sandia National Laboratories'
      @search_expectations.each do |key, val|
        expect(SiteItem.perform_search(SiteItem.prepare_strings(key), 1, false).size).to be > val
      end
      @blankline = BlogPost.displayed.where(base_path: '2021-06-ES4Blog3.md').first
      expect(@blankline.main).to match('<span class="caption">Figure 4')
      expect(@blankline.main).to match('<span class="caption">Figure 3')
      expect(Category.displayed.first.slug).to eq 'better-planning'
      expect(Fellow.displayed.where(base_path: '_HM_LowndesJu_2021.md').first.modified_path).to match('NSFcohort')
      expect(SiteItem.displayed.last.topic_list).not_to be_empty
      puts Rebuild.last.errors_encountered
      rebuild = Rebuild.where('started_at > ?', 10.minutes.ago).last
      expect(Rebuild.in_progress).to be_falsey
      rebuild.update_attribute(:ended_at, nil)
      expect(Rebuild.in_progress).to be_truthy
      
      expect do
        post :import
      end.not_to change(Rebuild, :count)

      expect(response).to redirect_to('/rebuilds')
    end
  end

  describe 'index' do
    it 'gets index' do
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials 'bssw', 'rebuildlog'
      request.env['HTTP_AUTHORIZATION'] = credentials
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'make displayed' do
    it 'changes the current id' do
      3.times { Rebuild.create }
      rs = RebuildStatus.first
      rs ||= RebuildStatus.find_or_create_by(display_rebuild_id: Rebuild.first.id)
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials 'bssw', 'rebuildlog'
      request.env['HTTP_AUTHORIZATION'] = credentials
      expect(Rebuild.first.id).not_to eq rs.display_rebuild_id
      expect do
        post :make_displayed, params: { id: Rebuild.first.id }
        rs.reload
      end.to change(rs, :display_rebuild_id)
    end
  end
end
