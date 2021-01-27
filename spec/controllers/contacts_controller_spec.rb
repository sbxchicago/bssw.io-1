# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactsController, type: :controller do
  Recaptcha.configuration.skip_verify_env.delete('test')
  render_views

  before(:each) do
    @rebuild = Rebuild.create
    RebuildStatus.all.each(&:destroy)
    RebuildStatus.create(display_rebuild_id: @rebuild.id)
    page = Page.create(name: 'Contact BSSw', rebuild_id: @rebuild.id, path: 'Contact.md')
    page.save
  end

  describe 'get new' do
    it 'renders the new template' do
      get :new
      expect(response).to render_template 'new'
    end
  end

  describe 'post create' do
    it 'sends mail' do
      allow_any_instance_of(ContactsController).to receive(:verify_recaptcha).and_return(true)
      expect do
        post :create, params: { contact_form: { name: 'foo', email: 'foo@example.com' } }
      end.to change(ActionMailer::Base.deliveries, :count)
    end

    it 'fails with bad info' do
      allow_any_instance_of(ContactsController).to receive(:verify_recaptcha).and_return(true)

      expect do
        post :create, params: { contact_form: { name: 'foo', email: 'foo' } }
      end.not_to change(ActionMailer::Base.deliveries, :count)
    end

    it 'wont send without recaptcha' do
      allow_any_instance_of(ContactsController).to receive(:verify_recaptcha).and_return(false)
      expect do
        post :create, params: { contact_form: { name: 'foo', email: 'foo@example.com' } }
      end.not_to change(ActionMailer::Base.deliveries, :count)
    end
  end
end
