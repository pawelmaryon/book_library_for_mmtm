# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "associations" do
    it "cannot be destroyed while books exist because of restriction" do
      tag  = create(:tag)
      book = create(:book, tag: tag)

      tag_id  = tag.id
      book_id = book.id

      # destroy should fail and return false
      result = tag.destroy

      expect(result).to be false
      expect(Tag.exists?(tag_id)).to be true
      expect(Book.exists?(book_id)).to be true

      # Rails should add a base error when using :restrict_with_error
      expect(tag.errors[:base]).not_to be_empty
    end
  end

  describe "validations" do
    it "is valid with a name" do
      tag = build(:tag, name: "fantasy")
      expect(tag).to be_valid
    end

    it "is invalid without a name" do
      tag = build(:tag, name: nil)

      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include("can't be blank")
    end

    it "validates uniqueness of name case-insensitively" do
      create(:tag, name: "fantasy")
      dup = build(:tag, name: "FANTASY")

      expect(dup).not_to be_valid
      expect(dup.errors[:name]).to include("has already been taken")
    end
  end

  describe "callbacks" do
    it "normalizes name by stripping, downcasing and squeezing spaces" do
      tag = Tag.create!(name: "  Sci   Fi  ")
      expect(tag.name).to eq("sci fi")
    end

    it "handles nil name safely in normalize_name" do
      tag = Tag.new(name: nil)
      tag.valid? # triggers before_validation

      expect(tag.name).to eq("")
    end
  end
end
