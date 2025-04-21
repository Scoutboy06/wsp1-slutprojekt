require_relative '../field'
require_relative '../media'

class UploadField < Field
  def initialize(name:, parent_slug:, required: false, default: nil, admin_visible: true)
    super(name: name, required: required, default: default, admin_visible: admin_visible)
    @parent_slug = parent_slug
    @type = 'upload'
  end

  def self.from_hash(hash, parent_slug)
    new(
      name: hash[:name],
      required: hash[:required],
      default: hash[:default],
      admin_visible: hash[:admin_visible],
      parent_slug: parent_slug
    )
  end

  def get_sql_column_string
    media_slug = CMS.media_collection.slug
    "\"#{@name}\" INTEGER REFERENCES \"#{media_slug}\"(id) ON DELETE #{@required ? 'CASCADE' : 'SET NULL'}"
  end

  def handle_insert(hash)
    value = hash.fetch(@name, nil)
    return [nil, true] if value.nil?

    meta = CMS.media_collection.insert(value)
    [meta[:id], true]
  end

  def fetch_nested_data(parent_id)
    sql = "SELECT * FROM \"#{CMS.media_collection.slug}\" WHERE id = (SELECT \"#{@name}\" FROM \"#{@parent_slug}\" WHERE id = ?)"
    execute_sql(sql, [parent_id], debug: true).first
  end

  def handle_update(record, _value)
    puts "Updating #{record}.#{@name} with upload data"
  end
end
