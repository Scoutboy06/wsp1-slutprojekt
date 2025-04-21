require_relative '../field'

class PasswordField < Field
  def initialize(name:, required: false, admin_visible: true)
    super(name: name, required: required, admin_visible: admin_visible)
    @type = 'password'
  end

  def self.from_hash(hash, _parent_slug = nil)
    new(
      name: hash[:name],
      required: hash[:required],
      admin_visible: hash[:admin_visible]
    )
  end

  def get_sql_column_string
    sql = "\"#{@name}\" TEXT"
    sql += ' NOT NULL' if @required
    sql
  end

  def handle_insert(hash)
    value = hash.fetch(@name, nil)
    return [nil, true] if value.nil?

    [BCrypt::Password.create(value), true]
  end

  def handle_update(record, value)
    puts "Updating #{record}.#{@name} with password: #{value}"
  end
end
