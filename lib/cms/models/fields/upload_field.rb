require_relative '../field'
require_relative '../media'

class UploadField < Field
  def initialize(name:, required: false, default: nil, admin_visible: true)
    super(name: name, required: required, default: default, admin_visible: admin_visible)
    @type = 'upload'
  end

  def self.from_hash(hash, _parent_slug = nil)
    new(
      name: hash[:name],
      required: hash[:required],
      default: hash[:default],
      admin_visible: hash[:admin_visible]
    )
  end

  def get_sql_column_string
    media_slug = CMS.media_collection.slug
    "\"#{@name}\" INTEGER REFERENCES \"#{media_slug}\"(id) ON DELETE #{@required ? 'CASCADE' : 'SET NULL'}"
  end

  def handle_insert(hash)
    value = hash.fetch(@name, nil)
    return nil if value.nil?

    meta = CMS.media_collection.insert(value)
    meta[:id]
  end

  def handle_update(record, _value)
    puts "Updating #{record}.#{@name} with upload data"
  end
end
