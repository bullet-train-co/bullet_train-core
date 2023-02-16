module Addresses::Continents::Base
  extend ActiveSupport::Concern

  included do
    self.data = JSON.parse(File.read(File.expand_path("../../../../../config/addresses/countries.json", File.dirname(__FILE__)))).map { |row| {id: row["region"], name: row["region"]} }.select { |row| row[:name].present? }.uniq
  end
end
