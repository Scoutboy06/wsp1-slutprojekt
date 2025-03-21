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
end
