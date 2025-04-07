require "tempfile"
require "fileutils"
require "mini_mime"
require "fastimage"
require_relative "./collection"

class Media
  def self.upload(db:, tempfile:, filename:, out_dir:)
    out_file_path = File.join(out_dir, filename)

    mime_type = MiniMime.lookup_by_filename(filename)&.content_type
    width = nil
    height = nil

    if mime_type&.start_with?('image/')
      dimensions = FastImage.size(tempfile.path)
      if dimensions
        width, height = dimensions
      else
        puts "Failed to determine image dimensions using FastImage"
      end
    end

    # 1. Create a database entry
    db.execute(
      "INSERT INTO media (file_path, url, file_name, mime_type, width, height, alt)
      VALUES (?,?,?,?,?,?,?)",
      ["temp", "temp", filename, mime_type, width, height, nil]
    )

    # 2. Get the last inserted ID
    id = db.last_insert_row_id
    disk_filename = "#{id}-#{filename}"
    disk_file_path = File.join(out_dir, disk_filename)
    url = '/' + disk_file_path.sub('public/', '')
    # puts "---------"
    # p filename
    # p out_dir
    # puts "--"
    # p disk_filename
    # p disk_file_path
    # p url
    # puts "---------"

    # 3. Move the uploaded file to the new location
    FileUtils.cp(tempfile.path, disk_file_path)

    # 4. Update the database entry with the correct file path and name
    db.execute(
      "UPDATE media
      SET file_path = ?, url = ?, file_name = ?
      WHERE id = ?",
      [disk_file_path, url, disk_filename, id]
    )

    { id: id, url: url, filename: disk_filename, path: disk_file_path }
  end

  def self.get_collection
    Collection.from_hash({
      name: "Media",
      slug: "media",
      fields: [
        { name: "file_path", type: "string", required: true },
        { name: "url", type: "string", required: true },
        { name: "file_name", type: "string", required: true },
        { name: "mime_type", type: "string", required: true },
        { name: "width", type: "number" },
        { name: "height", type: "number" },
        { name: "alt", type: "string" },
      ]
    })
  end

  def self.delete(db:, id:)
    puts "\n---- SQL to execute ----"
    puts "DELETE FROM media WHERE id = ?"
    puts "---- Values ----"
    p [id]

    db.execute("DELETE FROM media WHERE id = ?", [id])
  end

  def self.delete_by_id_expr(db:, id_expr:, values:)
    puts "\n---- SQL to execute ----"
    puts "DELETE FROM media WHERE id = (#{id_expr})"
    puts "---- Values ----"
    p [id]

    db.execute("DELETE FROM media WHERE id = (#{id_expr})", values)
  end
end
