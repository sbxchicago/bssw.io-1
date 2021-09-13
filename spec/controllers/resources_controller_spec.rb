# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourcesController, type: :controller do
  render_views

  before(:each) do
    FactoryBot.create(:page, name: 'Resources')
    @rebuild = Rebuild.create
    RebuildStatus.all.each(&:destroy)
    RebuildStatus.create(display_rebuild_id: @rebuild.id)
  end

  it 'deals with bad queries' do
    get 'search', params: { q: '%bm%&cp=0&hl=en-US&pq=%bm%&sourceid=chrome&ie=UTF-8' }
  end

  it 'shows not found page' do
    get :show, params: { id: 'foo' }
    expect(response.body).to match 'changing'
  end

  describe 'preview' do
    it 'is invalid without auth' do
      @request.host = 'preview.bssw.io'
      get 'index'
      expect(response).not_to render_template 'index'
    end

    it 'sets the preview val' do
      r = FactoryBot.create(:resource, publish: false, preview: true)
      @request.host = 'preview.bssw.io'
      @request.env['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('preview-bssw:SoMyCodeWillSeeTheFuture!!')}"
      get 'index'
      expect(response).to render_template 'index'
      expect(session[:preview]).to be true
      expect(assigns(:resources)).to include(r)
    end
  end

  describe 'get search' do
    it 'searches via preview' do
      @request.host = 'preview.bssw.io'
      @request.env['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('preview-bssw:SoMyCodeWillSeeTheFuture!!')}"
      resource = FactoryBot.create(:resource, publish: false, preview: true, type: 'Resource')
      expect(SiteItem.preview.displayed).to include(resource)
      get :search, params: { search_string: resource.name }
      expect(assigns(:resources)).to include(resource)
    end

    it 'renders template' do
      get :search
      expect(response).to render_template :index
    end

    it 'performs an empty search' do
      get :search, params: { search_string: 'foob' }
      expect(assigns(:resources)).to be_empty
    end

    it 'performs a simple search' do
      resource = FactoryBot.create(:resource, name: 'foob')
      get :search, params: { search_string: 'foob' }
      expect(assigns(:resources)).to include(resource)
    end

    it 'performs a simple search' do
      resource = FactoryBot.create(:resource, name: 'foob')
      get :search, params: { search_string: "'foob'" }
      expect(assigns(:resources)).to include(resource)
    end

    it 'finds fellows' do
      fellow = FactoryBot.create(:resource, name: 'bar bar')
      get :search, params: { search_string: 'bar' }
      expect(assigns(:resources)).to include(fellow)
    end

    it 'performs a more complex search' do
      resource = FactoryBot.create(:resource, content: 'Four score and seven')
      get :search, params: { search_string: 'four seven' }
      expect(assigns(:resources)).to include(resource)
    end

    it 'respects quote marks in search' do
      resource = FactoryBot.create(:resource, content: 'Four score and seven')
      get :search, params: { search_string: '"four seven"' }

      expect(assigns(:resources)).not_to include(resource)
    end

    it 'finds quoted terms in search' do
      resource = FactoryBot.create(:resource, content: 'Four score and seven')
      get :search, params: { search_string: '"four score"' }
      expect(assigns(:resources)).to include(resource)
    end

    it 'finds searches and renders' do
      resource = FactoryBot.create(:resource, content: 'search string')

      resource2 = FactoryBot.create(:resource, content: 'bloo bloo')
      FactoryBot.create(:blog_post, name: 'search string')
      expect(resource.content).not_to be_blank
      expect(Resource.all).to include(resource2)
      get :search, params: { search_string: 'search string' }
      expect(assigns(:search_string)).to eq('search string')
      expect(assigns(:resources)).to include(resource)
      expect(assigns(:resources)).not_to eq Resource.all
      expect(assigns(:resources)).not_to include(resource2)
      expect(response.body).to match '<mark>search'
    end
  end

  describe 'get authors' do
    it 'renders template' do
      FactoryBot.create(:author)
      RebuildStatus.all.each(&:destroy)
      RebuildStatus.create(display_rebuild_id: @rebuild.id)
      FactoryBot.create(:page, name: 'Contributors', path: 'Contributors.md', rebuild_id: @rebuild.id)
      get :authors
      expect(:response).to render_template :authors
    end
  end

  describe 'get show' do
    it 'renders the show template' do
      resource = FactoryBot.create(:resource, rebuild_id: @rebuild.id)

      resource.categories << FactoryBot.create(:category)
      get :show, params: { id: resource }
      expect(response).to render_template :show
    end

    it 'renders the show template or what_is / how_to' do
      what_is = FactoryBot.create(:what_is, publish: true, rebuild_id: @rebuild.id)
      get :show, params: { id: what_is }
      expect(response).to render_template 'resources/show'
    end
  end

  describe 'get index' do
    it 'renders the index template' do
      preview = FactoryBot.create(:resource, publish: false, preview: true)
      get :index, params: { view: 'all' }
      expect(response).to render_template :index
      expect(assigns(:resources)).not_to include(preview)
    end

    it 'displays pages' do
      150.times { FactoryBot.create(:resource) }
      get :index, params: { page: 1 }, xhr: true
      expect(response).to render_template :index
    end

    it 'can use topics' do
      topic = FactoryBot.create(:topic, rebuild_id: @rebuild.id)
      topiced_resource = FactoryBot.create(:resource, rebuild_id: @rebuild.id)
      untopiced_resource = FactoryBot.create(:resource, rebuild_id: @rebuild.id)
      topiced_resource.topics << topic
      get :index, params: { topic: topic.slug }
      expect(assigns(:resources)).to include(topiced_resource)
      expect(assigns(:resources)).not_to include(untopiced_resource)
      expect(assigns(:resources).size).to be < 2
    end

    it 'can use categories' do
      category = FactoryBot.create(:category, rebuild_id: @rebuild.id)
      topic = FactoryBot.create(:topic, category: category, rebuild_id: @rebuild.id)
      resource_with_category = FactoryBot.create(:resource, rebuild_id: @rebuild.id)
      resource_without_category = FactoryBot.create(:resource, rebuild_id: @rebuild.id)
      resource_with_category.topics << topic
      get :index, params: { category: category.slug }
      expect(assigns(:resources)).to include(resource_with_category)
      expect(assigns(:resources)).not_to include(resource_without_category)
    end

    it 'can use authors' do
      author = FactoryBot.create(:author, rebuild_id: @rebuild.id)
      resource_with_author = FactoryBot.create(:resource, rebuild_id: @rebuild.id)
      resource_without_author = FactoryBot.create(:resource, rebuild_id: @rebuild.id)
      resource_with_author.authors << author
      get :index, params: { author: author.slug }
      expect(assigns(:resources)).to include resource_with_author
      expect(assigns(:resources)).not_to include resource_without_author
    end

    it 'is in alpha order' do
      old_resource = FactoryBot.create(:resource, published_at: 1.week.ago, name: 'AA', rebuild_id: @rebuild.id)
      FactoryBot.create(:resource, published_at: 2.weeks.ago, rebuild_id: @rebuild.id)
      FactoryBot.create(:resource, published_at: Date.today, name: 'BB', rebuild_id: @rebuild.id)
      get :index
      expect(assigns(:resources).first).to eq old_resource
    end
  end

  describe 'rss feed' do
    it 'shows nothing' do
      5.times { FactoryBot.create(:resource) }
      get :index, format: :rss
      expect(assigns(:resources)).to be_empty
      expect(response.media_type).to eq 'application/rss+xml'
      expect(response).to be_ok
    end
    it 'shows feed' do
      5.times { FactoryBot.create(:resource, rss_date: 1.week.ago, rebuild_id: @rebuild.id) }
      get :index, format: :rss
      expect(assigns(:resources)).not_to be_empty
      expect(response.media_type).to eq 'application/rss+xml'
      expect(response).to be_ok
    end
  end
end
