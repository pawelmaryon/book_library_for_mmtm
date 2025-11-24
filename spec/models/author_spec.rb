# frozen_string_literal: true

require "rails_helper"

RSpec.describe Author, type: :model do
  describe "associations" do
    it "has many books and destroys them when the author is destroyed" do
      author = create(:author)
      book   = create(:book, author: author)

      expect(Book.exists?(book.id)).to be true

      expect {
        author.destroy
      }.to change { Book.count }.by(-1)

      expect(Book.exists?(book.id)).to be false
    end
  end

  describe "validations" do
    it "is valid with a name" do
      author = build(:author, name: "Terry Pratchett")
      expect(author).to be_valid
    end

    it "is invalid without a name" do
      author = build(:author, name: nil)

      expect(author).not_to be_valid
      expect(author.errors[:name]).to include("can't be blank")
    end

    it "validates uniqueness of name case-insensitively" do
      create(:author, name: "Terry Pratchett")
      dup = build(:author, name: "terry pratchett")

      expect(dup).not_to be_valid
      expect(dup.errors[:name]).to include("has already been taken")
    end
  end

  describe "callbacks" do
    it "normalizes name by stripping and squeezing spaces" do
      author = Author.create!(name: "  John   Doe  ")
      expect(author.name).to eq("John Doe")
    end

    it "handles nil name safely in normalize_name" do
      author = Author.new(name: nil)
      author.valid? # triggers before_validation

      expect(author.name).to eq("")
    end
  end
end
