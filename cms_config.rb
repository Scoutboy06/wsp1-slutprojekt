# Field types:
# - string
# - boolean
# - (array)
# - timestamp
# - upload

COLLECTIONS = [
  {
    name: "Posters",
    slug: "posters",
    upload: {
      staticDir: "public/media/posters",
      imageSizes: [
        {
          name: "thumbnail",
          width: 300,
          height: 450,
          position: "centre"
        },
        {
          name: "large",
          width: 1080,
          height: 1600,
        }
      ]
    },
    adminThumbnail: "thumbnail",
    mimeTypes: ["image/*"],
    fields: [{ name: "alt", type: "string" }]
  },
  {
    name: "Backdrops",
    slug: "backdrops",
    upload: {
      staticDir: "public/media/backdrops",
      imageSizes: [
        {
          name: "thumbnail",
          width: 400,
          height: 225,
        },
        {
          name: "large",
          width: 1920,
          height: 1080,
        }
      ]
    },
    adminThumbnail: "thumbnail",
    mimeTypes: ["image/*"],
    fields: [{ name: "alt", type: "text" }]
  },
  {
    name: "Users",
    slug: "users",
    fields: [
      { name: "email", type: "string", required: true },
      { name: "password", type: "string", required: true },
      { name: "first_name", type: "string" },
      { name: "last_name", type: "string" },
      { name: "phone", type: "string" },
      { name: "admin", type: "boolean", default: false },
    ],
  },
  {
    name: "Pages",
    slug: "pages",
    fields: [
      { name: "title", type: "string" },
      { name: "body", type: "string" },
    ]
  },
  {
    name: "Movies",
    slug: "movies",
    fields: [
      { name: "title", type: "string", required: true },
      { name: "description", type: "string" },
      { name: "tmdb_id", type: "string" },
      { name: "poster", type: "upload", relationTo: "posters" },
      { name: "backdrop", type: "upload", relationTo: "backdrops" },
    ]
  }
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
            relationTo: "pages",
            required: true,
          }
        ]
      }
    ]
  }
]
