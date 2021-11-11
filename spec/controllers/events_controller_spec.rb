# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  render_views

  before(:each) do
    @rebuild = Rebuild.create
    RebuildStatus.all.each(&:destroy)
    RebuildStatus.create(display_rebuild_id: @rebuild.id)
  end

  describe 'get index' do
    it 'shows future' do
      FactoryBot.create(:page, name: 'Upcoming Events', rebuild_id: @rebuild.id)
      event = FactoryBot.create(:event, publish: true)
      doc = Nokogiri::XML('<ul><li>Dates: December 10 - January 10 </li></ul>')
      event.send(:update_dates, doc.css("li:contains('Dates:')"))

      get :index
      expect(assigns(:upcoming_events)).not_to be_nil
    end
    it 'shows past' do
      FactoryBot.create(:page, name: 'Past Events', rebuild_id: @rebuild.id)
      event = FactoryBot.create(:event, publish: true)
      doc = Nokogiri::XML('<ul><li>Dates: January 1 2019 - January 10 2019</li></ul>')
      event.send(:update_dates, doc.css("li:contains('Dates:')"))
      get :index, params: { past: true }

      expect(assigns(:past_events)).not_to be_nil
    end

    it 'gets by author' do
      author = FactoryBot.create(:author, rebuild_id: @rebuild.id)
      author.save
      event = FactoryBot.create(:event, publish: true, authors: [author], rebuild_id: @rebuild.id)
      expect(Event.displayed).to include(event)
      expect(Event.displayed.with_author(author)).to include(event)
      doc = Nokogiri::XML('<ul><li>Dates: January 10 - January 10</li></ul>')
      event.send(:update_dates, doc.css("li:contains('Dates:')"))

      event.save

      expect(event.authors).to include(author)
      expect(Author.find_by(slug: author.slug)).to eq author

      expect(Event.with_author(author)).to include(event)
      get :index, params: { all: true, author: author.slug }
      expect(event.start_at).to eq event.end_at
      expect(assigns(:events)).to eq [event]
    end

    it 'gets unpaginated' do
      get :index, params: { view: 'all' }
      expect(response.body).not_to be_blank
    end
  end

  describe 'get show' do
    it 'shows an event' do
      event = FactoryBot.create(:event, rebuild_id: @rebuild.id)
      #      event.subresources << FactoryBot.create(:resource, rebuild_id: @rebuild.id)
      get :show, params: { id: event }
      expect(assigns(:event)).not_to be_nil
      expect(assigns(:resource)).not_to be_nil
    end
    it 'shows an event with a different date range' do
      event = FactoryBot.create(:event, start_at: 1.week.from_now, end_at: 2.weeks.from_now, rebuild_id: @rebuild.id)
      get :show, params: { id: event }
      expect(assigns(:event)).not_to be_nil
    end
  end
end
