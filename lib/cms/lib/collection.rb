require_relative "./field"
require_relative "./upload_config"

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
  end

  def select(db:, id: nil, limit: nil, offset: nil)
    exec_str = "SELECT * FROM #{self.slug}"
    exec_str << " WHERE id = ?" unless id.nil?
    exec_str << " LIMIT ?" unless limit.nil?
    exec_str << " OFFSET ?" unless offset.nil?

    values = []
    values << id unless id.nil?
    values << limit unless limit.nil?
    values << offset unless offset.nil?

    db.execute(exec_str, values)
  end

  def nested_select(all_collections:, id: nil, limit: nil, offset: nil, db:)
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

    data = db.execute(query_str, query_values)

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

  def insert(db:, data:)
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

    db.execute(exec_str, field_values)
  end

  def delete(db:, id:)
    db.execute("DELETE FROM #{self.slug} WHERE id = ?", [id])
  end
end
