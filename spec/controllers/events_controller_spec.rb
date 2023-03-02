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
      event = FactoryBot.create(:event, publish: true, rebuild_id: @rebuild.id)
      AdditionalDate.make_date('Submission Date', 1.week.from_now.to_s, event)
      AdditionalDate.make_date('Party Date', 2.weeks.from_now.to_s, event)
      FactoryBot.create(:page, name: 'Upcoming Events', rebuild_id: @rebuild.id)
      event = FactoryBot.create(:event, publish: true, rebuild_id: @rebuild.id)
      doc = Nokogiri::XML('<ul><li>Dates: December 10 - January 10 </li></ul>')
      event.send(:update_dates, doc.css("li:contains('Dates:')"))
      get :index
      expect(response.body).to match 'Submission'
    end

    it 'shows past' do
      FactoryBot.create(:page, name: 'Past Events', rebuild_id: @rebuild.id)
      200.times do
        event = FactoryBot.create(:event, publish: true, rebuild_id: @rebuild.id)
        doc = Nokogiri::XML('<ul><li>Dates: January 1 2019 - January 10 2019</li></ul>')
        event.send(:update_dates, doc.css("li:contains('Dates:')"))
        10.times do
          event.additional_dates.first.additional_date_values << FactoryBot.create(:additional_date_value,
                                                                                   date: 1.week.ago, additional_date: event.additional_dates.first)
        end
      end
      get :index, params: { past: true }
      get :index, params: { past: true, page: 2 }
      get :index, params: { past: true, page: 3 }
      get :index, params: { past: true, page: 4 }
      get :index, params: { past: true, page: 5 }

      expect(assigns(:events)).not_to be_nil
    end

    it 'shows past' do
      FactoryBot.create(:page, name: 'Past Events', rebuild_id: @rebuild.id)
      event = FactoryBot.create(:event, publish: true, rebuild_id: @rebuild.id)
      event.additional_dates << FactoryBot.create(:additional_date, label: 'foo', event: event)
      event.additional_dates.first.additional_date_values << FactoryBot.create(:additional_date_value,
                                                                               date: 1.week.ago, additional_date: event.additional_dates.first)
      get :index, params: { past: true }

      expect(assigns(:past_events)).to include(event)

      expect(assigns(:past_events)).not_to be_nil
    end

    it 'gets by author' do
      author = FactoryBot.create(:author, rebuild_id: @rebuild.id)
      author.save
      event = FactoryBot.create(:event, publish: true, rebuild_id: @rebuild.id)
      event.authors << author
      expect(Event.displayed).to include(event)
      expect(Event.displayed.with_author(author)).to include(event)
      doc = Nokogiri::XML('<ul><li>Dates: January 10 - January 10</li></ul>')
      event.send(:update_dates, doc.css("li:contains('Dates:')"))

      event.save

      expect(event.authors).to include(author)
      expect(Author.find_by(slug: author.slug)).to eq author

      expect(Event.displayed.published.with_author(author)).to include(event)

      get :index, params: { author: author.slug }
      expect(response.body).to include(event.name)
    end

    it 'gets unpaginated' do
      get :index, params: { view: 'all' }
      expect(response.body).not_to be_blank
    end
  end

  describe 'get show' do
    it 'shows an event' do
      event = FactoryBot.create(:event, publish: true, rebuild_id: @rebuild.id)
      event.additional_dates.all.each(&:destroy)
      expect(event.start_at).to be_blank
      AdditionalDate.make_date('Submission Date', 1.week.from_now.to_s, event)
      AdditionalDate.make_date('Party Date', 2.weeks.from_now.to_s, event)
      get :show, params: { id: event }
      expect(assigns(:event)).not_to be_nil
      expect(assigns(:resource)).not_to be_nil
    end
    it 'shows an event with a different date range' do
      event = FactoryBot.create(:event,
                                additional_dates: [
                                  FactoryBot.build(:additional_date,
                                                   label: 'Start Date',
                                                   additional_date_values: [FactoryBot.build(:additional_date_value,
                                                                                             date: Date.today.change(
                                                                                               month: 6, day: 1
                                                                                             ))]),
                                  FactoryBot.build(:additional_date,
                                                   label: 'End Date',
                                                   additional_date_values:
                                                     [FactoryBot.build(:additional_date_value,
                                                                       date: Date.today.change(month: 6, day: 10))]),
                                  FactoryBot.build(:additional_date,
                                                   label: 'Other Date',
                                                   additional_date_values:
                                                     [FactoryBot.build(:additional_date_value, date: 1.week.from_now)])
                                ],
                                rebuild_id: @rebuild.id)
      get :show, params: { id: event }
      expect(assigns(:event)).not_to be_nil
    end
  end
end
