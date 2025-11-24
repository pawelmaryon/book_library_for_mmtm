class Tag < ApplicationRecord
  #code below will make sure that if the tag will be deleted the book record will remain
  has_many :books, dependent: :nullify 

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false }

  before_validation :normalize_name

  private

  def normalize_name
    self.name = name.to_s.strip.downcase.squeeze(" ")
  end
end
