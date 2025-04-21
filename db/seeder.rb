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
    movies = CMS.collection('movies')
    media = CMS.collection('media')
    users = CMS.collection('users')
    genres = CMS.collection('genres')
    raise "Movies collection not found" if movies.nil?
    raise "Media collection not found" if media.nil?
    raise "Users collection not found" if users.nil?
    raise "Genres collection not found" if genres.nil?

    genres_data = [
      { "name" => "Epic", "slug" => "epic" },
      { "name" => "Drama", "slug" => "drama" },
      { "name" => "Romance", "slug" => "romance" },
      { "name" => "Anime", "slug" => "anime" },
      { "name" => "Coming-of-Age", "slug" => "coming-of-age" },
      { "name" => "Fairy Tale", "slug" => "fairy-tale" },
      { "name" => "Hand-Drawn Animation", "slug" => "hand-drawn-animation" },
      { "name" => "Quest", "slug" => "quest" },
      { "name" => "Supernatural Fantasy", "slug" => "supernatural-fantasy" },
      { "name" => "Adventure", "slug" => "adventure" },
      { "name" => "Animation", "slug" => "animation" },
      { "name" => "Family", "slug" => "family" },
      { "name" => "Fantasy", "slug" => "fantasy" },
    ]
    genres_ids = genres_data.map do |genre|
      genres.insert(genre)
      CMS.db.last_insert_row_id
    end

    movies.insert({
      "title" => "Forrest Gump",
      "description" => "Lorem ipsum",
      "tmdb_id" => "13-forrest-gump",
      "poster" => get_seeder_media('forrest_gump_poster.jpg'),
      "backdrop" => get_seeder_media('forrest_gump_backdrop.jpg'),
      "genres" => genres_ids[0..2]
    })

    movies.insert({
      "title" => "Spirited Away",
      "description" => "Lorem ipsum",
      "tmdb_id" => "129",
      "poster" => get_seeder_media('spirited_away_poster.jpg'),
      "backdrop" => get_seeder_media('spirited_away_backdrop.jpg'),
      "genres" => genres_ids[3..12]
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
