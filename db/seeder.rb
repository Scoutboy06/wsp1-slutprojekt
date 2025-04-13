require 'sqlite3'
require 'fileutils'
require 'pathname'
require 'tempfile'
require_relative '../lib/cms/lib'

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
    movies = CMS::Config.collections.find { |col| col.slug == "movies" }
    media = CMS::Config.collections.find { |col| col.slug == "media" }
    users = CMS::Config.collections.find { |col| col.slug == "users" }
    raise "Movies collection not found" if movies.nil?
    raise "Media collection not found" if media.nil?
    raise "Users collection not found" if users.nil?

    movies.insert({
      "title" => "Forrest Gump",
      "description" => "Lorem ipsum",
      "tmdb_id" => "13-forrest-gump",
      "poster" => get_seeder_media('forrest_gump_poster.jpg'),
      "backdrop" => get_seeder_media('forrest_gump_backdrop.jpg'),
    })

    movies.insert({
      "title" => "Spirited Away",
      "description" => "Lorem ipsum",
      "tmdb_id" => "129",
      "poster" => get_seeder_media('spirited_away_poster.jpg'),
      "backdrop" => get_seeder_media('spirited_away_backdrop.jpg'),
    })

    users.insert({
      "username" => "Admin",
      "email" => "admin@example.com",
      "password" => "password",
      "admin" => true,
    })
  end

  def self.get_seeder_media(filename)
    seeder_media_dir = File.expand_path('../seeder_media', __FILE__)
    file_path = File.join(seeder_media_dir, filename)

    {
      "filename" => filename,
      "tempfile" => File.open(file_path),
    }
  end
end
