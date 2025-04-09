require_relative "./field"
require_relative "./upload_config"
require_relative "./db_helpers"
require_relative '../lib'

class Collection
  include DatabaseOperations
  attr_reader :name, :slug, :upload, :admin_thumbnail, :mime_types, :fields

  def initialize(name:, slug:, upload: nil, admin_thumbnail: nil, mime_types: nil, fields: [])
    @name = name
    @slug = slug
    @upload = upload
    @admin_thumbnail = admin_thumbnail
    @mime_types = mime_types
    @fields = fields
  end

  def self.from_hash(hash)
    new(
      name: hash[:name],
      slug: hash[:slug],
      upload: hash[:upload] ? UploadConfig.from_hash(hash[:upload]) : nil,
      admin_thumbnail: hash[:admin_thumbnail],
      mime_types: hash[:mime_types],
      fields: hash[:fields]&.map { |f| Field.from_hash(f) } || [],
    )
  end

  def setup_db(db)
    field_strs = @fields.map { |f| f.get_sql_column_string }

    exec_str = "CREATE TABLE IF NOT EXISTS #{@slug} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      #{field_strs.join(",\n")}
    );"

    db.execute(exec_str)
    @db = db
  end

  def select(id: nil, limit: nil, offset: nil)
    exec_str, values = build_select_query(slug, id: id, limit: limit, offset: offset)
    @db.execute(exec_str, values)
  end

  def nested_select(id: nil, limit: nil, offset: nil)
    all_collections = CMS::Config.collections
    query_parts = []
    query_values = []

    ### start SELECT ###
    select_parts = ["#{self.slug}.*"]
    fields_with_relations = self.fields.select(&:relation_to)

    fields_with_relations.each do |field|
      field_collection = all_collections.find { |c| c.slug == field.relation_to }
      field_collection.fields.each do |col_field|
        select_parts << "#{field.name}_#{field.relation_to}.#{col_field.name} AS __#{field.name}_#{field.relation_to}_#{col_field.name}"
      end
    end
    query_parts << "SELECT #{select_parts.join(', ')}"
    ### end SELECT ###

    ### start FROM ###
    query_parts << "FROM #{self.slug}"
    ### end FROM ###

    ### start LEFT JOIN ###
    left_join_parts = fields_with_relations.map do |field|
      "LEFT JOIN #{field.relation_to} AS #{field.name}_#{field.relation_to} ON #{self.slug}.#{field.name} = #{field.name}_#{field.relation_to}.id"
    end
    query_parts << left_join_parts.join("\n  ")
    ### end LEFT JOIN ###

    ### start WHERE ###
    unless id.nil?
      query_parts << "WHERE #{self.slug}.id = ?"
      query_values << id
    end
    ### end WHERE ###

    query_str = query_parts.join("\n  ")
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
    exec_str, values = build_insert_query(slug, fields, data)
    execute_sql(exec_str, values)
  end

  def update(data:, id: nil)
    if slug == 'media'
      Media.replace(
        db: @db,
        tempfile: data['tempfile'],
        filename: data['filename'],
        out_dir: "public/uploads/",
      )
      return
    end

    query_parts = ["UPDATE #{self.slug} SET"]

    # Handle the SET clause for owned fields
    set_clauses = fields
      .reject(&:relation_to)
      .map { |field| "#{field.name} = ?"}
    query_parts << set_clauses.join(', ') if set_clauses.any?

    values = fields
      .reject(&:relation_to)
      .map { |field| data.fetch(field.name, nil) }

    # Handle the WHERE clause for updating a specific record
    unless id.nil?
      query_parts << "WHERE id = ?"
      values << id
    end

    execute_sql(query_parts.join("\n"), values)

    handle_related_collection_updates(data, id)
  end

  def update_by_id_expr(data:, id_expr:, values:)
    if slug == 'media'
      Media.replace_by_id_expr(
        db: @db,
        id_expr: id_expr,
        values: values,
        tempfile: data['tempfile'],
        filename: data['filename'],
        out_dir: 'public/uploads/',
      )
      return
    end

    exec_str, vals = build_update_query(slug, fields, data, id_expr: id_expr, values: values)
    execute_sql(exec_str, vals)

    handle_related_collection_updates(data, values.first)
    puts "------------------------"
  end

  def delete(id:)
    if self.slug == 'media'
      Media.delete(db: @db, id: id)
      return
    end
    execute_sql("DELETE FROM #{slug} WHERE id = ?", [id])
  end

  def delete_by_id_expr(id_expr:, values:)
    if self.slug == 'media'
      Media.delete_by_id_expr(db: @db, id_expr: id_expr, values: values)
      return
    end
    execute_sql(build_delete_query(slug, id_expr: id_expr), values)
  end

  private def handle_related_collection_updates(data, parent_id)
    CMS::Config.collections.each do |collection|
      relation_fields = fields.select { |f| f.relation_to == collection.slug }
      relation_fields.each do |field|
        updated_key = "#{field.name}__updated"
        next unless data.key?(updated_key)

        related_data = data.fetch(field.name, nil)
        if related_data.is_a?(Hash) && related_data.key?('tempfile') && related_data.key?('filename')
          media_id = collection.update_by_id_expr(
            data: related_data,
            id_expr: "SELECT #{field.name} FROM #{slug} WHERE id = ?",
            values: [parent_id],
          )
        elsif related_data.nil?
          collection.delete_by_id_expr(
            id_expr: "SELECT #{field.name} FROM #{slug} WHERE id = ?",
            values: [parent_id],
          )
        else
          collection.update_by_id_expr(
            data: related_data,
            id_expr: "SELECT #{field.name} FROM #{slug} WHERE id = ?",
            values: [parent_id],
          )
        end
      end
    end
  end

  private def update_parent_with_relation(parent_id, relation_field_name, related_id)
    exec_str = "UPDATE #{slug} SET #{relation_field_name} = ? WHERE id = ?"
    execute_sql(exec_str, [related_id, parent_id])
  end
end
