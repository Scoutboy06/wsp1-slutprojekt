require_relative '../field'

class EmailField < Field
  def initialize(name:, required: false, default: nil, admin_visible: true)
    super(name: name, required: required, default: default, admin_visible: admin_visible)
    @type = 'email'
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
    sql = "\"#{@name}\" TEXT"
    sql += ' NOT NULL' if @required
    sql += " DEFAULT '#{@default.gsub("'", "''")}'" if @default
    sql
  end

  def handle_update(record, value)
    puts "Updating #{record}.#{@name} with email: #{value}"
  end
end
