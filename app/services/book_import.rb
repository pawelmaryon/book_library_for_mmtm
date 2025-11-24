require "csv"

class BookImport
  Result = Struct.new(:total_rows, :imported_count, :errors, keyword_init: true)

  EXPECTED_HEADERS = %w[
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
  ].freeze

  def initialize(file)
    @file = file
  end

  def call
    errors      = []
    imported    = 0
    data_rows   = 0

    csv = CSV.new(@file.read, headers: true, header_converters: :downcase)

    validate_headers!(csv)

    ActiveRecord::Base.transaction do
      csv.each_with_index do |row, idx|
        line_number = idx + 2 # header is line 1

        next if blank_row?(row)

        data_rows += 1

        begin
          book = upsert_book_from_row(row)
          imported += 1 if book.persisted?
        rescue ActiveRecord::RecordInvalid => e
          errors << format_row_error(line_number, e.record)
        rescue StandardError => e
          errors << "Line #{line_number}: #{e.message}"
        end
      end
    end

    Result.new(
      total_rows: data_rows,
      imported_count: imported,
      errors: errors
    )
  end

  private

  def validate_headers!(csv)
    headers = csv.headers.compact.map(&:strip)
    missing = EXPECTED_HEADERS - headers
    raise StandardError, "Missing required headers: #{missing.join(', ')}" if missing.any?
  end

  def blank_row?(row)
    row.to_h.values.all? { |v| v.to_s.strip.empty? }
  end

  def upsert_book_from_row(row)
    attrs = normalized_attributes(row)

    book = find_existing_book(attrs)

    if book
      book.assign_attributes(attrs.except(:author_name, :tag_name))
    else
      book = Book.new(attrs.except(:author_name, :tag_name))
    end

    book.author = find_or_create_author(attrs[:author_name])
    book.tag    = find_or_create_tag(attrs[:tag_name]) if attrs[:tag_name].present?

    book.save!
    book
  end

  def normalized_attributes(row)
    authors_str = row["authors"].to_s
    first_author = authors_str.split(/;|,/).first.to_s.strip

    tags_str = row["tags"].to_s
    first_tag = tags_str.split(/;|,/).first.to_s.strip

    {
      title:            row["title"].to_s.strip,
      author_name:      first_author,
      tag_name:         first_tag.presence,
      isbn:             row["isbn13"].to_s.strip.presence,
      publication_year: int_or_nil(row["publication_year"]),
      series_name:      row["series_name"].to_s.strip.presence,
      series_position:  int_or_nil(row["series_position"]),
      pages:            int_or_nil(row["pages"]),
      price_pence:      int_or_nil(row["price_pence"]),
      currency:         row["currency"].to_s.strip.presence,
      tags_raw:         tags_str.presence
    }
  end

  def int_or_nil(value)
    Integer(value, exception: false)
  end

  def find_existing_book(attrs)
    if attrs[:isbn].present?
      Book.find_by(isbn: attrs[:isbn])
    else
      Book.find_by(
        title:          attrs[:title],
        series_name:    attrs[:series_name],
        series_position: attrs[:series_position]
      )
    end
  end

  def find_or_create_author(name)
    raise StandardError, "Author name is blank" if name.blank?

    Author.find_or_create_by!(name: name)
  end

  def find_or_create_tag(name)
    Tag.find_or_create_by!(name: name.strip.downcase)
  end

  def format_row_error(line_number, record)
    "Line #{line_number}: #{record.errors.full_messages.join(', ')}"
  end
end
