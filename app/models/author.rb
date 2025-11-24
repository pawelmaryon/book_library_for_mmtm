class Author < ApplicationRecord
  #if author will be removed the book will be removed as well
  has_many :books, dependent: :destroy

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false }

  before_validation :normalize_name

  private

  def normalize_name
    self.name = name.to_s.strip.squeeze(" ")
  end
end
