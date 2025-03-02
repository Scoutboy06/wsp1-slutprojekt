require "tempfile"
require "fileutils"
require_relative "./collection"

class Media
  def self.upload(db:, tempfile:, filename:, file_path:)
    # 1. Create a database entry
    db.execute(
      "INSERT INTO media (file_path, file_name, mime_type, width, height, alt)
      VALUES (?, ?, ?, ?, ?, ?)",
      [file_path, filename, "image/jpeg", 300, 400, nil]
    )

    # 2. Get the last inserted ID
    id = db.last_insert_row_id
    disk_filename = "#{id}-#{filename}"
    disk_file_path = File.join(file_path, disk_filename)

    # 3. Move the uploaded file to the new location
    FileUtils.mv(tempfile.path, disk_file_path)

    # 4. Update the database entry with the correct file path and name
    db.execute(
      "UPDATE media
      SET file_path = ?, file_name = ?
      WHERE id = ?",
      [disk_file_path, disk_filename, id]
    )

    { id: id, filename: disk_filename, path: disk_file_path }
  rescue => e
    puts "Upload failed: #{e.message}"
    nil
  end

  def self.get_collection
    Collection.from_hash({
      name: "Media",
      slug: "media",
      fields: [
        { name: "file_path", type: "string", required: true },
        { name: "file_name", type: "string", required: true },
        { name: "mime_type", type: "string", required: true },
        { name: "width", type: "number", required: true },
        { name: "height", type: "number", required: true },
        { name: "alt", type: "string" },
      ]
    })
  end
end
