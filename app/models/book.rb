class Book < ApplicationRecord
  belongs_to :author
  belongs_to :tag

  validates :title, presence: true

  validates :isbn,
            uniqueness: true,
            allow_nil: true,
            format: {
              with: /\A[0-9\-xX]+\z/,
              message: "must contain only digits"
            },
            length: { maximum: 20 }

  validates :publication_year,
            allow_nil: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 100
            }

  validates :pages,
            allow_nil: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            }

  validates :price_pence,
            allow_nil: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }
  validates :series_position,
            allow_nil: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            }


  scope :with_title_like, ->(q) {
    where("LOWER(books.title) LIKE ?", "%#{q.downcase}%") if q.present?
  }

  scope :with_author_like, ->(q) {
    return if q.blank?

    joins(:author)
      .where("LOWER(authors.name) LIKE ?", "%#{q.downcase}%")
  }

  scope :with_tag_like, ->(q) {
    return if q.blank?

    joins(:tag)
      .where("LOWER(tags.name) LIKE ?", "%#{q.downcase}%")
  }

  def formatted_price
    return nil if price_pence.blank?

    (price_pence.to_f / 100).round(2)
  end
end
