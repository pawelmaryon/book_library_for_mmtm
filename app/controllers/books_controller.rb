class BooksController < ApplicationController
  def index
    @filters = {
      title:       params[:title],
      author:      params[:author],
      tag:         params[:tag],
      series_name: params[:series_name]
    }

    @books = Book.includes(:author, :tag).order(:title)

    if @filters[:title].present?
      @books = @books.with_title_like(@filters[:title])
    end

    if @filters[:author].present?
      @books = @books.with_author_like(@filters[:author])
    end

    if @filters[:tag].present?
      @books = @books.with_tag_like(@filters[:tag])
    end

    if @filters[:series_name].present?
      @books = @books.where(
        "LOWER(series_name) LIKE ?",
        "%#{@filters[:series_name].downcase}%"
      )
    end
  end

  def show
    @book = Book.includes(:author, :tag).find(params[:id])
  end
end
