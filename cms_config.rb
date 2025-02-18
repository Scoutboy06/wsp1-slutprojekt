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
      static_dir: "public/media/posters",
      image_sizes: [
        {
          name: "thumbnail",
          width: 300,
          height: 450,
          position: "centre",
        },
        {
          name: "large",
          width: 1080,
          height: 1600,
        },
      ],
    },
    admin_thumbnail: "thumbnail",
    mime_types: ["image/*"],
    fields: [{ name: "alt", type: "string" }],
  },
  {
    name: "Backdrops",
    slug: "backdrops",
    upload: {
      static_dir: "public/media/backdrops",
      image_sizes: [
        {
          name: "thumbnail",
          width: 400,
          height: 225,
        },
        {
          name: "large",
          width: 1920,
          height: 1080,
        },
      ],
    },
    admin_thumbnail: "thumbnail",
    mime_types: ["image/*"],
    fields: [{ name: "alt", type: "text" }],
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
    ],
  },
  {
    name: "Movies",
    slug: "movies",
    fields: [
      { name: "title", type: "string", required: true },
      { name: "description", type: "string" },
      { name: "tmdb_id", type: "string" },
      { name: "poster", type: "upload", relation_to: "posters" },
      { name: "backdrop", type: "upload", relation_to: "backdrops" },
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
