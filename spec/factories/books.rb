FactoryBot.define do
  factory :book do
    title { "MyString" }
    isbn { "MyString" }
    publication_year { 1 }
    pages { 1 }
    price_pence { 1 }
    currency { "MyString" }
    author { nil }
    tag { nil }
    series_position { 1 }
    series_name { "MyString" }
  end
end
