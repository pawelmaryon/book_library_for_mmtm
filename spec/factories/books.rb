# frozen_string_literal: true

FactoryBot.define do
  factory :book do
    association :author
    association :tag

    title { Faker::Book.title }
    isbn { Faker::Number.number(digits: 13).to_s }
    publication_year { Faker::Number.between(from: 100, to: 2025) }
    pages { Faker::Number.between(from: 1, to: 1_000) }
    price_pence { Faker::Number.between(from: 0, to: 10_000) }
    currency { "GBP" }
    series_name { "Some Series" }
    series_position { Faker::Number.between(from: 1, to: 20) }
  end
end
