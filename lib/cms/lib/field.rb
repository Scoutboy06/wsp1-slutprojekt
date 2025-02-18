class Field
  attr_reader :name, :type, :required, :default, :relation_to, :fields

  def initialize(name:, type:, required: false, default: nil, relation_to: nil, fields: [])
    @name = name
    @type = type
    @required = required
    @default = default
    @relation_to = relation_to
    @fields = fields
  end

  def self.from_hash(hash)
    new(
      name: hash[:name],
      type: hash[:type],
      required: hash[:required] || false,
      default: hash[:default],
      relation_to: hash[:relation_to],
      fields: hash[:fields]&.map { |f| Field.from_hash(f) } || [],
    )
  end
end
