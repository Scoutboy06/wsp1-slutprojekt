require_relative '../utils/db_helpers'

class Field
  include DatabaseOperations
  attr_reader :name, :required, :default, :admin_visible, :type

  def initialize(name:, required: false, default: nil, admin_visible: true)
    @name = name
    @required = required
    @default = default
    @admin_visible = admin_visible
    @db = CMS::Config.db
  end

  def self.from_hash(hash, parent_slug)
    type = hash[:type]
    field_class = case type
                  when 'number' then NumberField
                  when 'string' then StringField
                  when 'boolean' then BooleanField
                  when 'upload' then UploadField
                  when 'email' then EmailField
                  when 'password' then PasswordField
                  when 'array' then ArrayField
                  when 'relation' then RelationField
                  else raise "Invalid field type: `#{type}` for field `#{hash[:name]}`"
                  end

    # Extract common parameters with defaults
    common_params = {
      name: hash[:name],
      required: hash[:required] || false,
      default: hash[:default],
      admin_visible: hash.fetch(:admin_visible, true) # Use fetch with default
    }

    field_class.from_hash(common_params.merge(hash), parent_slug)
  end

  def get_base_sql_column_string
    parts = []
    parts << "\"#{@name}\""
    parts << 'NOT NULL' if @required
    parts << "DEFAULT '#{@default.gsub("'", "''")}'" if @default
    parts.join(' ')
  end

  # To be overridden by subclasses if they need to create a table
  # The default implementation does nothing.
  def create_sql_table; end

  # To be overridden by subclasses if they need custom column definitions
  def get_sql_column_string
    get_base_sql_column_string
  end

  # To be overridden by subclasses if they need to handle updates.
  # Either returns a value to be inserted in an INSERT statement, or executes a custom SQL statement.
  # The default implementation returns the value to be inserted.
  # @return [String, Boolean] The value to be inserted in the database and a boolean indicating whether to insert it.
  def handle_insert(hash)
    [hash.fetch(@name, nil), true]
  end

  def handle_deferred_insert(_items, _parent_id)
    raise NotImplementedError, 'Subclasses that use deferred insert must implement handle_deferred_insert'
  end

  # Default implementation for fetching nested data
  # @param parent_id [Integer] The ID of the parent record
  # @return [nil] Returns nil by default, subclasses should override this method if needed.
  def fetch_nested_data(_parent_id)
    nil
  end

  def handle_update(record, value)
    raise NotImplementedError, 'Subclasses must implement handle_update'
  end
end
