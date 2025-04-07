require 'sqlite3'
require 'fileutils'
require 'pathname'
require 'tempfile'
require_relative '../lib/cms/lib'
require_relative '../lib/cms/lib/media'

class Seeder
  def self.seed!
    # Delete the SQLite database file
    db_path = File.expand_path('../cms_db.sqlite', __FILE__)
    FileUtils.rm_f(db_path) if File.exist?(db_path)

    # Clean /public/uploads directory except .gitignore
    uploads_dir = File.expand_path('../../public/uploads', __FILE__)
    Dir.foreach(uploads_dir) do |file|
      next if file == '.' || file == '..' || file == '.gitignore'

      path = File.join(uploads_dir, file)
      FileUtils.rm_rf(path)
    end

    CMS::Config.load

    # Upload media in /db/seeder_media
    media_files = [
      'forrest_gump_backdrop.jpg',
      'forrest_gump_poster.jpg',
      'spirited_away_backdrop.jpg',
      'spirited_away_poster.jpg'
    ]

    seeder_media_dir = File.expand_path('../seeder_media', __FILE__)
    project_root = File.expand_path('../../', __FILE__)

    db = CMS::Config.db

    file_meta = media_files.map do |filename|
      file_path = File.join(seeder_media_dir, filename)

      raise "File not found: #{filename}" unless File.exist?(file_path)

      Media.upload(
        db: db,
        tempfile: File.open(file_path),
        filename: filename,
        out_dir: 'public/uploads/',
      )
    end

    movies_collection = CMS::Config.collections.find { |col| col.slug == "movies" }

    # Forrest gump
    movies_collection.insert({
      "title" => "Forrest Gump",
      "description" => "Lorem ipsum",
      "tmdb_id" => "13-forrest-gump",
      "poster" => file_meta[1][:id],
      "backdrop" => file_meta[0][:id],
    })

    # Spirited away
    movies_collection.insert({
      "title" => "Spirited Away",
      "description" => "Lorem ipsum",
      "tmdb_id" => "129",
      "poster" => file_meta[3][:id],
      "backdrop" => file_meta[2][:id],
    })
  end
end
