# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookImport do
  def build_file(contents)
    StringIO.new(contents)
  end

  let(:headers) do
    %w[
      title
      authors
      isbn13
      publication_year
      series_name
      series_position
      pages
      price_pence
      currency
      tags
    ]
  end

  describe "#call" do
    context "with valid CSV" do
      let(:csv) do
        <<~CSV
          #{headers.join(",")}
          The Colour of Magic,Terry Pratchett,9780552138932,1983,Discworld,1,285,799,GBP,Fantasy
          American Gods,Neil Gaiman,9780062572233,2001,, ,465,999,USD,Fantasy;Mythology
        CSV
      end

      it "imports all valid rows" do
        result = described_class.new(build_file(csv)).call

        expect(result.total_rows).to eq(2)
        expect(result.imported_count).to eq(2)
        expect(result.errors).to be_empty

        book = Book.find_by(isbn: "9780552138932")
        expect(book).to be_present
        expect(book.title).to eq("The Colour of Magic")
        expect(book.author.name).to eq("Terry Pratchett")
        expect(book.tag.name).to eq("fantasy")
      end

      it "handles CRLF line endings" do
        crlf_csv = csv.gsub("\n", "\r\n")

        result = described_class.new(build_file(crlf_csv)).call

        expect(result.total_rows).to eq(2)
        expect(result.imported_count).to eq(2)
      end

      it "uses only the first author and first tag from semicolon/comma separated lists" do
        multi_csv = <<~CSV
          #{headers.join(",")}
          Good Omens,"Terry Pratchett; Neil Gaiman",9780060853983,1990,, ,288,899,GBP,"Fantasy,Comedy"
        CSV

        result = described_class.new(build_file(multi_csv)).call

        expect(result.imported_count).to eq(1)
        book = Book.find_by(isbn: "9780060853983")
        expect(book.author.name).to eq("Terry Pratchett")
        expect(book.tag.name).to eq("fantasy")
      end
    end

    context "when headers are missing" do
      let(:bad_csv) do
        <<~CSV
          title,authors,isbn13
          Book Title,Some Author,1234567890123
        CSV
      end

      it "raises an error about missing headers" do
        expect do
          described_class.new(build_file(bad_csv)).call
        end.to raise_error(StandardError, /Missing required headers/)
      end
    end

    context "with blank rows" do
      let(:csv_with_blank_rows) do
        <<~CSV
          #{headers.join(",")}
          The Colour of Magic,Terry Pratchett,9780552138932,1983,Discworld,1,285,799,GBP,Fantasy

          ,,,,,,,,,
          American Gods,Neil Gaiman,9780062572233,2001,, ,465,999,USD,Fantasy
        CSV
      end

      it "ignores completely blank rows" do
        result = described_class.new(build_file(csv_with_blank_rows)).call

        expect(result.total_rows).to eq(2) # only the two data rows
        expect(result.imported_count).to eq(2)
      end
    end

    context "when some rows are invalid" do
      let(:csv_with_invalid) do
        <<~CSV
          #{headers.join(",")}
          ,Terry Pratchett,9780552138932,1983,Discworld,1,285,799,GBP,Fantasy
          American Gods,Neil Gaiman,9780062572233,2001,, ,465,999,USD,Fantasy
        CSV
      end

      it "imports valid rows and returns errors for invalid ones" do
        result = described_class.new(build_file(csv_with_invalid)).call

        expect(result.total_rows).to eq(2)
        expect(result.imported_count).to eq(1)
        expect(result.errors.size).to eq(1)
        expect(result.errors.first).to match(/Line 2:/)

        expect(Book.find_by(isbn: "9780062572233")).to be_present
      end
    end

    context "when author name is blank" do
      let(:csv_blank_author) do
        <<~CSV
          #{headers.join(",")}
          Some Book,,9780552138932,1983,Discworld,1,285,799,GBP,Fantasy
        CSV
      end

      it "adds a generic error for the row" do
        result = described_class.new(build_file(csv_blank_author)).call

        expect(result.total_rows).to eq(1)
        expect(result.imported_count).to eq(0)
        expect(result.errors.first).to match(/Line 2: Author name is blank/)
      end
    end

    context "upsert behaviour" do
      it "updates existing book when isbn matches" do
        author = create(:author, name: "Old Author")
        tag    = create(:tag, name: "old tag")
        book   = create(:book,
                        title: "Old Title",
                        isbn: "9780552138932",
                        author: author,
                        tag: tag)

        csv = <<~CSV
          #{headers.join(",")}
          New Title,Terry Pratchett,9780552138932,1983,Discworld,1,285,799,GBP,Fantasy
        CSV

        result = described_class.new(build_file(csv)).call

        expect(result.imported_count).to eq(1)
        book.reload
        expect(book.title).to eq("New Title")
        expect(book.author.name).to eq("Terry Pratchett")
        expect(book.tag.name).to eq("fantasy")
      end

      it "upserts by title + series_name + series_position when isbn is blank" do
        existing = create(
          :book,
          isbn: nil,
          title: "The Colour of Magic",
          series_name: "Discworld",
          series_position: 1
        )

        csv = <<~CSV
          #{headers.join(",")}
          The Colour of Magic,Terry Pratchett,,1983,Discworld,1,300,799,GBP,Fantasy
        CSV

        result = described_class.new(build_file(csv)).call

        expect(result.imported_count).to eq(1)
        existing.reload
        expect(existing.pages).to eq(300)
        expect(existing.author.name).to eq("Terry Pratchett")
      end
    end

    context "integer parsing" do
      let(:csv) do
        <<~CSV
          #{headers.join(",")}
          Weird Numbers,Terry Pratchett,9780552138932,not_a_year,,not_number,not_pages,not_price,GBP,Fantasy
        CSV
      end

      it "converts invalid integers to nil and may cause validation errors" do
        result = described_class.new(build_file(csv)).call

        expect(result.total_rows).to eq(1)
        expect(result.imported_count + result.errors.size).to eq(1)
      end
    end
  end
end