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

  def handle_insert(value)
    return [nil, true] if value.nil?

    # If we receive a hash, it's a new record to create
    if value.is_a?(Hash)
      relation_col = CMS.find_by_slug(@relation_to)
      relation_col.insert(value)
      [CMS::Config.db.last_insert_row_id, true]
    # If we receive an integer, it's an existing record ID
    elsif value.is_a?(Integer)
      [value, true]
    else
      raise ArgumentError, "Invalid value for relation field #{@name}: #{value.inspect}"
    end
  end

  def handle_update(record, value)
    puts "Update relation field #{record}.#{@name} with value: #{value}"
  end

  def fetch_nested_data(parent_id)
    sql = "SELECT * FROM \"#{@relation_to}\" WHERE \"#{@name}\" = ?"
    result = execute_sql(sql, parent_id).first
    related_id = result&.fetch(@name)
    return nil unless related_id

    related_collection = CMS.find_by_slug(@relation_to)
    related_collection.nested_select(id: related_id).first
  end
end
