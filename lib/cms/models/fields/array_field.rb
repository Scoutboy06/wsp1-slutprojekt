require_relative '../field'

class ArrayField < Field
  attr_reader :fields

  def initialize(name:, fields:, parent_slug:, default: nil, admin_visible: true)
    super(name: name, default: default, admin_visible: admin_visible)
    @fields = fields
    @parent_field = RelationField.new(
      name: parent_slug,
      relation_to: parent_slug,
      required: true
    )
    @type = 'array'
    @table_name = "#{parent_slug}__#{name}__items"
  end

  def self.from_hash(hash, parent_slug)
    new(
      name: hash[:name],
      fields: hash[:fields]&.map { |f| Field.from_hash(f) } || [],
      # TODO: default: hash[:default],
      admin_visible: hash[:admin_visible],
      parent_slug: parent_slug
    )
  end

  def create_sql_table
    parts = ["CREATE TABLE IF NOT EXISTS \"#{@table_name}\" ("]
    columns = [
      'id INTEGER PRIMARY KEY AUTOINCREMENT',
      "\"#{@parent_field.name}\" INTEGER REFERENCES \"#{@parent_field.relation_to}\"(id) ON DELETE CASCADE"
    ]
    @fields.each(&:create_sql_table)
    columns.push(*@fields.map(&:get_sql_column_string))
    parts << columns.join(",\n")
    parts << ');'

    sql = parts.join("\n")
    execute_sql(sql, debug: true)
  end

  def get_sql_column_string
    nil
  end

  def handle_insert(hash)
    data = hash.fetch(@name, nil)
    return [nil, false] if data.nil?

    raise "Invalid data for field `#{@name}`: #{data.inspect}" unless data.is_a?(Array)

    [data, :defer_insert]
  end

  def handle_deferred_insert(items, parent_id)
    items.each do |value|
      parts = ["INSERT INTO \"#{@table_name}\""]

      field_names = ["\"#{@parent_field.name}\""]
      values = [parent_id]
      @fields.each do |field|
        insert_value, should_include = field.handle_insert(value)
        if should_include
          field_names << field.name
          values << insert_value
        end
      end

      parts << "(#{field_names.join(', ')})"
      parts << 'VALUES'
      parts << "(#{field_names.map { |_f| '?' }.join(',')})"

      exec_str = parts.join("\n")
      execute_sql(exec_str, values, debug: true)
    end

    [nil, false]
  end
end
