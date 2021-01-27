# frozen_string_literal: true

# display categories
class CategoriesController < ApplicationController
  def show
    @category = Category.find(params[:id])
  end
end
