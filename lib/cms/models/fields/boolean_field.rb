require_relative '../field'

class BooleanField < Field
  def initialize(name:, required: false, default: nil, admin_visible: true)
    super(name: name, required: required, default: default, admin_visible: admin_visible)
    @type = 'boolean'
  end

  def self.from_hash(hash, _parent_slug = nil)
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

  def handle_insert(hash)
    value = hash.fetch(@name, nil)
    return [nil, true] if value.nil?
    return [1, true] if [true, 'on'].include?(value)
    return [0, true] if [false, 'off'].include?(value)

    raise "Invalid value for boolean field `#{@name}`: #{value.inspect}"
  end

  def handle_update(record, value)
    puts "Updating #{record}.#{@name} with boolean: #{value}"
  end
end
