require_relative "./field"

class Global
  attr_reader :name, :slug, :fields

  def initialize(name:, slug:, fields: [])
    @name = name
    @slug = slug
    @fields = fields
  end

  def self.from_hash(hash)
    new(
      name: hash[:name],
      slug: hash[:slug],
      fields: hash[:fields]&.map { |f| Field.from_hash(f) },
    )
  end
end
