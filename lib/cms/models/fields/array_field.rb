require_relative '../field'

class ArrayField < Field
  def initialize(name:, fields:, default: nil, admin_visible: true)
    super(name: name, default: default, admin_visible: admin_visible)
    @fields = fields
    @type = 'array'
  end

  def self.from_hash(hash)
    new(
      name: hash[:name],
      fields: hash[:fields]&.map { |f| Field.from_hash(f) } || [],
      # TODO: default: hash[:default],
      admin_visible: hash[:admin_visible]
    )
  end
end
