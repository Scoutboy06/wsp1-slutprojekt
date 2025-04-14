require "tempfile"
require "fileutils"
require "mini_mime"
require "fastimage"
require_relative "./collection"
require_relative "./db_helpers"

class Media < Collection
  extend DatabaseOperations

  def self.build_config(name: "Media", upload_path:, custom_fields: [])
    @@upload_path = upload_path

    fields = [
      { name: "file_path", type: "string", required: true },
      { name: "url", type: "string", required: true },
      { name: "file_name", type: "string", required: true },
      { name: "mime_type", type: "string", required: true },
      { name: "width", type: "number" },
      { name: "height", type: "number" },
    ]
    fields.push(*custom_fields)

    { name: name, slug: "media", fields: fields, __internal_class: :media }
  end

  def insert(data)
    raise "Parameter `data` not provided" if data.nil?
    tempfile = data['tempfile']
    filename = data['filename']
    mime_type = MiniMime.lookup_by_filename(filename)&.content_type
    width, height = FastImage.size(tempfile.path) if mime_type&.start_with?('image/')

    # 1. Create a database entry
    execute_sql(
      "INSERT INTO media (file_path, url, file_name, mime_type, width, height)
      VALUES (?,?,?,?,?,?)",
      ["temp", "temp", filename, mime_type, width, height],
    )
    id = @db.last_insert_row_id

    # 2. Get the last inserted ID
    disk_filename = "#{id}-#{filename}"
    disk_file_path = File.join(@@upload_path, disk_filename)
    url = '/' + disk_file_path.sub('public/', '')

    # 3. Copy the uploaded file to the new location
    FileUtils.cp(tempfile.path, disk_file_path)

    # 4. Update the database entry with the final file path, URL, and filename
    execute_sql(
      "UPDATE media
      SET file_path = ?, url = ?, file_name = ?
      WHERE id = ?",
      [disk_file_path, url, disk_filename, id],
    )

    { id: id, url: url, filename: disk_filename, path: disk_file_path }
  end

  def update(id:, data:, id_expr: '?')
    raise "Parameter `data` not provided" if data.nil?
    tempfile = data['tempfile']
    filename = data['filename']

    # 1. Get the old file path
    old_media_data = execute_sql("SELECT file_path, id FROM media WHERE id = (#{id_expr})", [id]).first
    raise "No old media" if old_media_data.nil?

    old_file_path = old_media_data['file_path']
    db_id = old_media_data['id']

    # 2. Determine new file details
    mime_type = MiniMime.lookup_by_filename(filename)&.content_type
    width, height = FastImage.size(tempfile.path) if mime_type&.start_with?('image/')
    disk_filename = "#{db_id}-#{filename}"
    disk_file_path = File.join(@@upload_path, disk_filename)
    url = '/' + disk_file_path.sub('public/', '')

    # 3. Delete the old file from disk
    File.delete(old_file_path) if File.exist?(old_file_path)

    # 4. Copy the new uploaded file to the old location (with the new filename)
    FileUtils.cp(tempfile.path, disk_file_path)

    # 5. Update the existing database record
    execute_sql(
      "UPDATE media
      SET file_path = ?, url = ?, file_name = ?
      WHERE id = (#{id_expr})",
      [disk_file_path, url, disk_filename, id],
    )

    { id: id, url: url, filename: disk_filename, path: disk_file_path }
  end

  def delete(id:, id_expr: '?')
    media_data = execute_sql(
      "SELECT file_path FROM media WHERE id = (#{id_expr})", [id]
    ).first
    return if media_data.nil?

    file_path = media_data['file_path']
    File.delete(file_path) if File.exist?(file_path)

    execute_sql("DELETE FROM media WHERE id = (#{id_expr})", [id])
  end
end
