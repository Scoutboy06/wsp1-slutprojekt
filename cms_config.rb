require "sqlite3"

DB = SQLite3::Database.new "db/cms_db.sqlite"
DB.results_as_hash = true
DB.execute("PRAGMA foreign_keys = ON;")

# Field types:
# - string
# - boolean
# - (array)
# - timestamp
# - upload

COLLECTIONS = [
  {
    name: "Users",
    slug: "users",
    fields: [
      { name: "email", type: "email", required: true },
      { name: "password", type: "password", required: true, admin_visible: false },
      { name: "first_name", type: "string" },
      { name: "last_name", type: "string" },
      { name: "phone", type: "string" },
      { name: "admin", type: "boolean", default: false, admin_visible: false },
    ],
  },
  {
    name: "Pages",
    slug: "pages",
    fields: [
      { name: "title", type: "string" },
      { name: "body", type: "string" },
    ],
  },
  {
    name: "Movies",
    slug: "movies",
    fields: [
      { name: "title", type: "string", required: true },
      { name: "description", type: "string" },
      { name: "tmdb_id", type: "string" },
      { name: "poster", type: "upload", relation_to: "media" },
      { name: "backdrop", type: "upload", relation_to: "media" },
    ],
  },
]

GLOBALS = [
  {
    name: "Navigation items",
    slug: "nav",
    fields: [
      {
        name: "items",
        type: "array",
        required: true,
        fields: [
          {
            name: "page",
            type: "relationship",
            relation_to: "pages",
            required: true,
          },
        ],
      },
    ],
  },
]
