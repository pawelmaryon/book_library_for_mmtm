class AuthorsController < ApplicationController
  def index
    @authors = Author.pluck(:name, :id)
  end

  def show
    @author = Author.find(params[:id])
    @books = @author.books
  end
end
