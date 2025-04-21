require_relative './fields/all_fields'
require_relative '../utils/db_helpers'
require_relative '../lib'

class Collection
  include DatabaseOperations
  attr_reader :name, :slug, :fields, :icon

  def initialize(name:, slug:, fields: [], icon: nil)
    @name = name
    @slug = slug
    @fields = fields
    @icon = icon
  end

  def self.from_hash(hash)
    case hash[:__internal_class]
    when :media
      Media.new(
        name: hash[:name],
        slug: hash[:slug],
        fields: hash[:fields]&.map { |f| Field.from_hash(f) } || [],
        icon: hash[:icon]
      )
    when :user
      User.new(
        name: hash[:name],
        slug: hash[:slug],
        fields: hash[:fields]&.map { |f| Field.from_hash(f) } || [],
        icon: hash[:icon]
      )
    else
      new(
        name: hash[:name],
        slug: hash[:slug],
        fields: hash[:fields]&.map { |f| Field.from_hash(f, hash[:slug]) } || [],
        icon: hash[:icon]
      )
    end
  end

  def setup_db(db)
    @db = db
    fields.each(&:create_sql_table)
    field_strs = ['"id" INTEGER PRIMARY KEY AUTOINCREMENT']
    field_strs.push(*fields.map(&:get_sql_column_string).compact)

    exec_str = "CREATE TABLE IF NOT EXISTS \"#{@slug}\" (\n#{field_strs.join(",\n")}\n);"

    execute_sql(exec_str)
  end

  def select(id: nil, limit: nil, offset: nil)
    exec_str, values = build_select_query(slug, id: id, limit: limit, offset: offset)
    execute_sql(exec_str, values)
  end

  def select_by(limit: nil, offset: nil, **args)
    conditions = args.map { |key, _value| "#{key} = ?" }.join(' AND ')
    values = args.values

    sql = "SELECT * FROM #{slug}"
    sql += " WHERE #{conditions}" unless conditions.empty?
    sql += ' LIMIT ?' if limit
    sql += ' OFFSET ?' if offset

    values += [limit, offset].compact

    execute_sql(sql, values)
  end

  def select_by_either(limit: nil, offset: nil, **args)
    conditions = args.map { |key, _value| "#{key} = ?" }.join(' OR ')
    values = args.values

    sql = "SELECT * FROM #{slug}"
    sql += " WHERE #{conditions}" unless conditions.empty?
    sql += ' LIMIT ?' if limit
    sql += ' OFFSET ?' if offset

    values += [limit, offset].compact

    execute_sql(sql, values)
  end

  def nested_select(id: nil, limit: nil, offset: nil)
    all_collections = CMS::Config.collections
    query_parts = []
    query_values = []

    ### start SELECT ###
    select_parts = ["#{slug}.*"]
    fields_with_relations = fields.select(&:relation_to)

    fields_with_relations.each do |field|
      field_collection = all_collections.find { |c| c.slug == field.relation_to }
      field_collection.fields.each do |col_field|
        select_parts << "#{field.name}_#{field.relation_to}.#{col_field.name} AS __#{field.name}_#{field.relation_to}_#{col_field.name}"
      end
    end
    query_parts << "SELECT #{select_parts.join(', ')}"
    ### end SELECT ###

    ### start FROM ###
    query_parts << "FROM #{slug}"
    ### end FROM ###

    ### start LEFT JOIN ###
    left_join_parts = fields_with_relations.map do |field|
      "LEFT JOIN #{field.relation_to} AS #{field.name}_#{field.relation_to} ON #{slug}.#{field.name} = #{field.name}_#{field.relation_to}.id"
    end
    query_parts << left_join_parts.join("\n  ")
    ### end LEFT JOIN ###

    ### start WHERE ###
    unless id.nil?
      query_parts << "WHERE #{slug}.id = ?"
      query_values << id
    end
    ### end WHERE ###

    query_str = query_parts.join("\n")
    data = execute_sql(query_str, query_values)

    data.each do |result_item|
      fields_with_relations.each do |field|
        field_hash = {}
        field_collection = all_collections.find { |c| c.slug == field.relation_to }

        field_collection.fields.each do |col_field|
          query_name = "__#{field.name}_#{field.relation_to}_#{col_field.name}"
          query_value = result_item[query_name]
          field_hash[col_field.name] = query_value
          result_item.delete(query_name)
        end

        result_item[field.name] = field_hash
      end
    end

    data
  end

  def insert(data)
    parts = ["INSERT INTO \"#{slug}\""]
    deferred_inserts = []

    field_names = []
    values = []
    @fields.each do |field|
      value, should_include = field.handle_insert(data)
      if should_include == :defer_insert
        deferred_inserts << [field, value]
      elsif should_include
        field_names << "\"#{field.name}\""
        values << value
      end
    end

    parts << "(#{field_names.join(', ')})"
    parts << 'VALUES'
    parts << "(#{field_names.map { |_f| '?' }.join(',')})"

    exec_str = parts.join("\n")
    execute_sql(exec_str, values)

    parent_id = @db.last_insert_row_id
    deferred_inserts.each do |field, items|
      field.handle_deferred_insert(items, parent_id)
    end
  end

  def update(id:, data:, id_expr: '?')
    query_parts = ["UPDATE \"#{slug}\" SET"]

    set_clauses = fields
                  .reject { |f| f.relation_to || f.type == 'password' }
                  .map { |field| "'#{field.name}' = ?" }
    values = fields
             .reject { |f| f.relation_to || f.type == 'password' }
             .map do |field|
      value = data.fetch(field.name, nil)
      value = [true, 'on'].include?(value) ? 1 : 0 if field.type == 'password'
      value
    end

    password_fields_to_update = fields.select do |f|
      f.type == 'password' && data.key?(f.name) && data.fetch(f.name) != ''
    end

    password_fields_to_update.each do |field|
      set_clauses << "'#{field.name}' = ?"
      values << BCrypt::Password.create(data.fetch(field.name))
    end

    fields_with_relations = fields.select { |f| f.relation_to }
    fields_with_relations.each do |field|
      value = data.fetch(field.name, nil)
      is_deleted = data.key?(field.name + '__deleted')
      relation_col = CMS::Config.collections.find { |c| c.slug == field.relation_to }

      # 4 possible cases:
      # !value && !is_deleted => Do nothing
      # !value && is_deleted => Delete
      # value && !is_deleted => Create
      # value && is_deleted => Update

      if !value && is_deleted
        relation_col.delete(
          id_expr: "SELECT #{field.name} FROM #{slug} WHERE id = ?",
          id: id
        )
      elsif value && !is_deleted
        relation_col.insert(value)
        set_clauses << "#{field.name} = ?"
        values << @db.last_insert_row_id
      elsif value && is_deleted
        relation_col.update(
          id_expr: "SELECT #{field.name} FROM #{slug} WHERE id = ?",
          id: id,
          data: value
        )
      end
    end

    query_parts << set_clauses.join(', ') if set_clauses.any?
    query_parts << "WHERE id = (#{id_expr})"
    values.push(id)

    exec_str = query_parts.join("\n")
    execute_sql(exec_str, values)
  end

  def delete(id:, id_expr: '?')
    execute_sql("DELETE FROM #{slug} WHERE id = (#{id_expr})", [id])
  end
end
