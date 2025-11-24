# frozen_string_literal: true

require "rails_helper"

RSpec.describe Book, type: :model do
  describe "associations" do
    it "belongs to an author" do
      book = build(:book, author: nil)

      expect(book).not_to be_valid
      expect(book.errors[:author]).to include("must exist")
    end

    it "belongs to a tag" do
      book = build(:book, tag: nil)

      expect(book).not_to be_valid
      expect(book.errors[:tag]).to include("must exist")
    end
  end

  describe "validations" do
    it "is valid with factory defaults" do
      expect(build(:book)).to be_valid
    end

    describe "title" do
      it "requires a title" do
        book = build(:book, title: nil)

        expect(book).not_to be_valid
        expect(book.errors[:title]).to include("can't be blank")
      end
    end

    describe "isbn" do
      it "allows nil" do
        book = build(:book, isbn: nil)
        expect(book).to be_valid
      end

      it "enforces uniqueness" do
        isbn = "1234567890123"
        create(:book, isbn: isbn)
        dup = build(:book, isbn: isbn)

        expect(dup).not_to be_valid
        expect(dup.errors[:isbn]).to include("has already been taken")
      end

      it "rejects invalid characters" do
        book = build(:book, isbn: "ABC123!!")

        expect(book).not_to be_valid
        expect(book.errors[:isbn]).to include("must contain only digits")
      end

      it "accepts digits, x/X and hyphens" do
        book = build(:book, isbn: "978-1-4028-9462-x")

        expect(book).to be_valid
      end

      it "rejects too long values (> 20 chars)" do
        book = build(:book, isbn: "1" * 21)

        expect(book).not_to be_valid
        expect(book.errors[:isbn]).to be_present
      end
    end

    describe "publication_year" do
      it "allows nil" do
        book = build(:book, publication_year: nil)
        expect(book).to be_valid
      end

      it "rejects non-integer values" do
        book = build(:book, publication_year: 99.5)

        expect(book).not_to be_valid
        expect(book.errors[:publication_year]).to be_present
      end

      it "rejects values less than 100" do
        book = build(:book, publication_year: 99)

        expect(book).not_to be_valid
        expect(book.errors[:publication_year]).to be_present
      end
    end

    describe "pages" do
      it "allows nil" do
        book = build(:book, pages: nil)
        expect(book).to be_valid
      end

      it "rejects non-integer" do
        book = build(:book, pages: 1.5)
        expect(book).not_to be_valid
        expect(book.errors[:pages]).to be_present
      end

      it "rejects <= 0" do
        book = build(:book, pages: 0)
        expect(book).not_to be_valid
        expect(book.errors[:pages]).to be_present
      end
    end

    describe "price_pence" do
      it "allows nil" do
        book = build(:book, price_pence: nil)
        expect(book).to be_valid
      end

      it "rejects non-integer" do
        book = build(:book, price_pence: 10.5)
        expect(book).not_to be_valid
        expect(book.errors[:price_pence]).to be_present
      end

      it "rejects negative values" do
        book = build(:book, price_pence: -1)
        expect(book).not_to be_valid
        expect(book.errors[:price_pence]).to be_present
      end
    end

    describe "series_position" do
      it "allows nil" do
        book = build(:book, series_position: nil)
        expect(book).to be_valid
      end

      it "rejects non-integer" do
        book = build(:book, series_position: 1.5)
        expect(book).not_to be_valid
        expect(book.errors[:series_position]).to be_present
      end

      it "rejects <= 0" do
        book = build(:book, series_position: 0)
        expect(book).not_to be_valid
        expect(book.errors[:series_position]).to be_present
      end
    end
  end

  describe "scopes" do
    let!(:author1) { create(:author, name: "Terry Pratchett") }
    let!(:author2) { create(:author, name: "Neil Gaiman") }

    let!(:tag1) { create(:tag, name: "fantasy") }
    let!(:tag2) { create(:tag, name: "horror") }

    let!(:book1) { create(:book, title: "Guards! Guards!", author: author1, tag: tag1) }
    let!(:book2) { create(:book, title: "Good Omens", author: author2, tag: tag2) }

    describe ".with_title_like" do
      it "returns books with case-insensitive title match" do
        result = described_class.with_title_like("guards")

        expect(result).to contain_exactly(book1)
      end

      it "returns all books when query is blank (no extra filter)" do
        result = described_class.with_title_like("")

        expect(result).to match_array(described_class.all)
      end
    end

    describe ".with_author_like" do
      it "returns books with case-insensitive author match" do
        result = described_class.with_author_like("pratchett")

        expect(result).to contain_exactly(book1)
      end

      it "returns all books when query is blank (no extra filter)" do
        result = described_class.with_author_like(nil)

        expect(result).to match_array(described_class.all)
      end
    end

    describe ".with_tag_like" do
      it "returns books with case-insensitive tag match" do
        result = described_class.with_tag_like("fantasy")

        expect(result).to contain_exactly(book1)
      end

      it "returns all books when query is blank (no extra filter)" do
        result = described_class.with_tag_like("")

        expect(result).to match_array(described_class.all)
      end
    end
  end

  describe "#formatted_price" do
    it "returns nil when price_pence is nil" do
      book = build(:book, price_pence: nil)
      expect(book.formatted_price).to be_nil
    end

    it "returns price in pounds with 2 decimal places" do
      book = build(:book, price_pence: 1234)
      expect(book.formatted_price).to eq(12.34)
    end
  end
end
