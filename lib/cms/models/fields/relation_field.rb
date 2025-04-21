require_relative '../field'

class RelationField < Field
  attr_reader :relation_to

  def initialize(name:, relation_to:, required: false, admin_visible: true)
    super(name: name, required: required, admin_visible: admin_visible)
    @relation_to = relation_to
    @type = 'relation'
  end

  def self.from_hash(hash, _parent_slug = nil)
    new(
      name: hash[:name],
      relation_to: hash[:relation_to],
      required: hash[:required],
      admin_visible: hash[:admin_visible]
    )
  end

  def get_sql_column_string
    "\"#{name}\" INTEGER REFERENCES \"#{@relation_to}\"(id) ON DELETE #{@required ? 'CASCADE' : 'SET NULL'}"
  end

  def handle_update(record, value)
    puts "Update relation field #{record}.#{@name} with value: #{value}"
  end
end
