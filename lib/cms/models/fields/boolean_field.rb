require_relative '../field'

class BooleanField < Field
  def initialize(name:, required: false, default: nil, admin_visible: true)
    super(name: name, required: required, default: default, admin_visible: admin_visible)
    @type = 'boolean'
  end

  def self.from_hash(hash)
    new(
      name: hash[:name],
      required: hash[:required],
      default: hash[:default],
      admin_visible: hash[:admin_visible]
    )
  end

  def get_sql_column_string
    "#{get_base_sql_column_string} BOOLEAN"
  end

  def handle_update(record, value)
    puts "Updating #{record}.#{@name} with boolean: #{value}"
  end
end
