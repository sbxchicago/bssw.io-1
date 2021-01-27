# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributesController, type: :controller do
  describe 'get new' do
    it 'renders the new template' do
      get :new
      expect(response).to render_template 'new'
    end
  end

  describe 'post create' do
    it 'sends mail' do
      allow_any_instance_of(ContributesController).to receive(:verify_recaptcha).and_return(true)
      expect do
        post :create, params: { contribute: { name: 'foo', email: 'foo@example.com' } }
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end
end
