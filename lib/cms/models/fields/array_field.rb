require_relative '../field'

class ArrayField < Field
  attr_reader :fields

  def initialize(name:, fields:, parent_slug:, default: nil, admin_visible: false)
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
      fields: hash[:fields]&.map { |f| Field.from_hash(f, parent_slug) } || [],
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
    execute_sql(sql)
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
    items.each do |item|
      parts = ["INSERT INTO \"#{@table_name}\""]

      field_names = ["\"#{@parent_field.name}\""]
      values = [parent_id]
      @fields.each do |field|
        field_value = item.fetch(field.name, nil)
        insert_value, should_include = field.handle_insert(field_value)
        if should_include
          field_names << field.name
          values << insert_value
        end
      end

      parts << "(#{field_names.join(', ')})"
      parts << 'VALUES'
      parts << "(#{field_names.map { |_f| '?' }.join(',')})"

      exec_str = parts.join("\n")
      execute_sql(exec_str, values)
    end

    [nil, false]
  end


  def fetch_nested_data(parent_id)
    result = {}

    non_relation_fields = @fields.reject { |f| f.is_a?(RelationField) }
    relation_fields = @fields.select { |f| f.is_a?(RelationField) }

    non_relation_fields.each do |field|
      result[field.name] = field.fetch_nested_data(item['id']) || item[field.name]
    end

    # We do a LEFT JOIN for relation fields

    # Example query:
    # SELECT t2.*
    # FROM "movies__genres__items" AS t1
    # LEFT JOIN "genres" AS t2
    # ON t2.id = t1.genre
    # WHERE t1."movies" = ?;

    query = "SELECT " # Select all columns from the array table
    selects = []
    joins = []
    select_fields = []

    relation_fields.each_with_index do |field, index|
      alias_name = "t#{index + 2}" # t2, t3, etc.
      selects << "#{alias_name}.*" # Select all columns from the related table
      joins << "LEFT JOIN \"#{field.relation_to}\" AS #{alias_name} ON #{alias_name}.id = t1.#{field.name}"
      select_fields << field.name
    end

    query += selects.join(' ') if selects.any?
    query += " FROM \"#{@table_name}\" AS t1 "
    query += joins.join(' ')
    query += " WHERE t1.\"#{@parent_field.name}\" = ?"

    items = execute_sql(query, [parent_id], debug: true)
    puts "Items:"
    p items

    # Process the joined results
    items.map do |item|
      result = {}

      relation_fields.each do |field|
    end

    result
  end
end
