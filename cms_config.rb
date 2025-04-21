require 'sqlite3'
require_relative 'lib/cms/lib'

DB = SQLite3::Database.new 'db/cms_db.sqlite'
DB.results_as_hash = true
DB.execute('PRAGMA foreign_keys = ON;')

COLLECTIONS = [
  CMS.build_user_config(
    use_pfp: true,
    custom_fields: [
      { name: 'first_name', type: 'string' },
      { name: 'last_name', type: 'string' },
      { name: 'phone', type: 'string' },
      { name: 'admin', type: 'boolean', default: false, admin_visible: false }
    ]
  ),
  CMS.build_media_config(
    upload_path: 'public/uploads/',
    custom_fields: [
      { name: 'alt', type: 'string' }
    ]
  ),
  {
    name: 'Pages',
    slug: 'pages',
    icon: 'web',
    fields: [
      { name: 'title', type: 'string' },
      { name: 'body', type: 'string' }
    ]
  },
  {
    name: 'Movies',
    slug: 'movies',
    icon: 'movie',
    fields: [
      { name: 'title', type: 'string', required: true },
      { name: 'description', type: 'string' },
      { name: 'tmdb_id', type: 'string' },
      { name: 'poster', type: 'upload' },
      { name: 'backdrop', type: 'upload' },
      { name: 'genres', type: 'array', fields: [
        { name: 'genre', type: 'relation', relation_to: 'genres' }
      ]}
    ]
  },
  {
    name: "Genres",
    slug: "genres",
    icon: "label",
    fields: [
      { name: 'name', type: 'string', required: true },
      { name: 'slug', type: 'string', required: true },
    ]
  }
]

GLOBALS = [
  {
    name: 'Theme',
    slug: 'theme',
    icon: 'color_lens',
    fields: [
      { name: 'background', type: 'string', default: '0 0% 100%' },
      { name: 'foreground', type: 'string', default: '224 71.4% 4.1%' },
      { name: 'card', type: 'string', default: '0 0% 100%' },
      { name: 'card_foreground', type: 'string', default: '224 71.4% 4.1%' },
      { name: 'popover', type: 'string', default: '0 0% 100%' },
      { name: 'popover_foreground', type: 'string', default: '224 71.4% 4.1%' },
      { name: 'primary', type: 'string', default: '262.1 83.3% 57.8%' },
      { name: 'primary_foreground', type: 'string', default: '210 20% 98%' },
      { name: 'secondary', type: 'string', default: '220 14.3% 95.9%' },
      { name: 'secondary_foreground', type: 'string', default: '220.9 39.3% 11%' },
      { name: 'muted', type: 'string', default: '220 14.3% 95.9%' },
      { name: 'muted_foreground', type: 'string', default: '220 8.9% 46.1%' },
      { name: 'accent', type: 'string', default: '220 14.3% 95.9%' },
      { name: 'accent_foreground', type: 'string', default: '220.9 39.3% 11%' },
      { name: 'destructive', type: 'string', default: '0 84.2% 60.2%' },
      { name: 'destructive_foreground', type: 'string', default: '210 20% 98%' },
      { name: 'border', type: 'string', default: '220 13% 91%' },
      { name: 'input', type: 'string', default: '220 13% 91%' },
      { name: 'ring', type: 'string', default: '262.1 83.3% 57.8%' },
      { name: 'radius', type: 'string', default: '0.5rem' },
      { name: 'chart_1', type: 'string', default: '12 76% 61%' },
      { name: 'chart_2', type: 'string', default: '173 58% 39%' },
      { name: 'chart_3', type: 'string', default: '197 37% 24%' },
      { name: 'chart_4', type: 'string', default: '43 74% 66%' },
      { name: 'chart_5', type: 'string', default: '27 87% 67%' }
    ]
  },
  {
    name: 'Dark theme',
    slug: 'dark_theme',
    icon: 'dark_mode',
    fields: [
      { name: 'background', type: 'string', default: '224 71.4% 4.1%' },
      { name: 'foreground', type: 'string', default: '210 20% 98%' },
      { name: 'card', type: 'string', default: '224 71.4% 4.1%' },
      { name: 'card_foreground', type: 'string', default: '210 20% 98%' },
      { name: 'popover', type: 'string', default: '224 71.4% 4.1%' },
      { name: 'popover_foreground', type: 'string', default: '210 20% 98%' },
      { name: 'primary', type: 'string', default: '263.4 70% 50.4%' },
      { name: 'primary_foreground', type: 'string', default: '210 20% 98%' },
      { name: 'secondary', type: 'string', default: '215 27.9% 16.9%' },
      { name: 'secondary_foreground', type: 'string', default: '210 20% 98%' },
      { name: 'muted', type: 'string', default: '215 27.9% 16.9%' },
      { name: 'muted_foreground', type: 'string', default: '217.9 10.6% 64.9%' },
      { name: 'accent', type: 'string', default: '215 27.9% 16.9%' },
      { name: 'accent_foreground', type: 'string', default: '210 20% 98%' },
      { name: 'destructive', type: 'string', default: '0 62.8% 30.6%' },
      { name: 'destructive_foreground', type: 'string', default: '210 20% 98%' },
      { name: 'border', type: 'string', default: '215 27.9% 16.9%' },
      { name: 'input', type: 'string', default: '215 27.9% 16.9%' },
      { name: 'ring', type: 'string', default: '263.4 70% 50.4%' },
      { name: 'chart_1', type: 'string', default: '220 70% 50%' },
      { name: 'chart_2', type: 'string', default: '160 60% 45%' },
      { name: 'chart_3', type: 'string', default: '30 80% 55%' },
      { name: 'chart_4', type: 'string', default: '280 65% 60%' },
      { name: 'chart_5', type: 'string', default: '340 75% 55%' }
    ]
  }
]
