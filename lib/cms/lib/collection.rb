require_relative "./field"
require_relative "./upload_config"
require_relative '../lib'

class Collection
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
    exec_str = "SELECT * FROM #{self.slug}"
    exec_str << " WHERE id = ?" unless id.nil?
    exec_str << " LIMIT ?" unless limit.nil?
    exec_str << " OFFSET ?" unless offset.nil?

    values = []
    values << id unless id.nil?
    values << limit unless limit.nil?
    values << offset unless offset.nil?

    @db.execute(exec_str, values)
  end

  def nested_select(id: nil, limit: nil, offset: nil)
    all_collections = CMS::Config.collections
    query_parts = []
    query_values = []

    ### start SELECT ###
    select_parts = []
    select_parts << "#{self.slug}.*"

    fields_with_relations = self.fields
      .select { |field| !!field.relation_to }

    for field in fields_with_relations
      # field = { name: "poster", type: "upload", relation_to: "media" }

      field_collection = all_collections.find { |c| c.slug == field.relation_to }

      for col_field in field_collection.fields
        select_parts << "#{field.name}_#{field.relation_to}.#{col_field.name} AS __#{field.name}_#{field.relation_to}_#{col_field.name}"
      end
    end

    query_parts << "SELECT #{select_parts.join(', ')}"
    ### end SELECT ###

    ### start FROM ###
    query_parts << "FROM #{self.slug}"
    ### end FROM ###

    ### start LEFT JOIN ###
    left_join_parts = []

    for field in fields_with_relations
      # media ON movies.poster = media.id
      left_join_parts << "LEFT JOIN #{field.relation_to} AS #{field.name}_#{field.relation_to} ON #{self.slug}.#{field.name} = #{field.name}_#{field.relation_to}.id"
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

    data = @db.execute(query_str, query_values)

    for result_item in data
      for field in fields_with_relations
        field_hash = {}

        field_collection = all_collections.find { |c| c.slug == field.relation_to }

        for col_field in field_collection.fields
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
    field_names = self.fields.map { |field| field.name }
    field_values = self.fields.map do |field|
      value = data.fetch(field.name, nil)
      value = 1 if value == true
      value = 0 if value == false
      value = BCrypt::Password.create(value) if field.type == "password"
      value
    end

    exec_str = "INSERT INTO #{self.slug}
      (#{field_names.join(', ')})
      VALUES (#{field_names.map { |_| '?' }.join(',')})
    "

    @db.execute(exec_str, field_values)
  end

  def update(data:, id: nil)
    puts "------------------------"
    p data
    query_parts = []
    values = []

    # Construct the UPDATE statement
    query_parts << "UPDATE #{self.slug}"

    # Handle the SET clause for owned fields
    owned_fields = self.fields.select { |field| !field.relation_to }
    set_clauses = owned_fields.map do |field|
      value = data.fetch(field.name, nil)
      values << value
      "#{field.name} = ?"
    end
    query_parts << "SET #{set_clauses.join(', ')}" if set_clauses.any?

    # Handle the WHERE clause for updating a specific record
    unless id.nil?
      query_parts << "WHERE id = ?"
      values << id
    end

    exec_str = query_parts.join("\n")

    puts "\n---- SQL to execute ----"
    puts exec_str
    puts "---- Values ----"
    p values

    @db.execute(exec_str, values)

    # Handle updates for related collections
    CMS::Config.collections.each do |collection|
      relation_fields = fields.select { |f| f.relation_to == collection.slug }
      relation_fields.each do |field|
        updated_key = "#{field.name}__updated"
        next unless data.key?(updated_key)

        related_data = data.fetch(field.name, nil)
        if related_data.nil?
          collection.delete_by_id_expr(
            id_expr: "SELECT #{field.name} FROM #{self.slug} WHERE id = ?",
            values: [id],
          )
        else
          collection.update_by_id_expr(
            data: related_data,
            id_expr: "SELECT #{field.name} FROM #{self.slug} WHERE id = ?",
            values: [id]
          )
        end
      end
    end
    puts "------------------------"
  end

  def update_by_id_expr(data:, id_expr:, values:)
    puts "------------------------"
    p data

    if self.slug == 'media'
      Media.delete_by_id_expr(
        db: @db,
        id_expr: id_expr,
        values: values,
      )
      media_meta = Media.upload(
        db: @db,
        tempfile: data['tempfile'],
        filename: data['filename'],
        out_dir: "public/uploads/",
      )
      return
    end

    query_parts = []
    vals = []

    # Construct the UPDATE statement
    query_parts << "UPDATE #{self.slug}"

    # Handle the SET clause for owned fields
    owned_fields = self.fields.select { |field| !field.relation_to }
    set_clauses = owned_fields.map do |field|
      value = data.fetch(field.name, nil)
      vals << value
      "#{field.name} = ?"
    end
    query_parts << "SET #{set_clauses.join(', ')}" if set_clauses.any?

    # Handle the WHERE clause for updating a specific record
    query_parts << "WHERE id = (#{id_expr})"
    vals.push(*values)

    exec_str = query_parts.join("\n")

    puts "\n---- SQL to execute ----"
    puts exec_str
    puts "---- Values ----"
    p vals

    @db.execute(exec_str, vals)

    # Handle updates for related collections
    CMS::Config.collections.each do |collection|
      relation_fields = fields.select { |f| f.relation_to == collection.slug }
      relation_fields.each do |field|
        updated_key = "#{field.name}__updated"
        next unless data.key?(updated_key)

        related_data = data.fetch(field.name, nil)
        if related_data.nil?
          collection.delete_by_id_expr(
            id_expr: "SELECT #{field.name} FROM #{self.slug} WHERE id = #{id_expr}",
            values: [id],
          )
        else
          collection.update_by_id_expr(
            data: related_data,
            id_expr: "SELECT #{field.name} FROM #{self.slug} WHERE id = (#{id_expr})",
            values: [id]
          )
        end
      end
    end
    puts "------------------------"
  end

  def delete(id:)
    if self.slug == 'media'
      Media.delete(db: @db, id: id)
      return
    end

    exec_str = "DELETE FROM #{self.slug} WHERE id = ?"
    @db.execute(exec_str, [id])
  end

  def delete_by_id_expr(id_expr:, values:)
    if self.slug == 'media'
      Media.delete_by_id_expr(db: @db, id_expr: id_expr, values: values)
      return
    end

    exec_str = "DELETE FROM #{self.slug} WHERE id = (#{id_expr})"
    @db.execute(exec_str, values)
  end
end
