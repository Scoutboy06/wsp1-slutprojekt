class Field
  attr_reader :name, :required, :default, :admin_visible

  def initialize(name:, required: false, default: nil, admin_visible: true)
    @name = name
    @required = required
    @default = default
    @admin_visible = admin_visible
  end

  def self.from_hash(hash)
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
    field_class.from_hash(hash)
  end

  def get_base_sql_column_string
    parts = []
    parts << "\"#{@name}\""
    parts << 'NOT NULL' if @required
    parts << "DEFAULT '#{@default.gsub("'", "''")}'" if @default
    parts.join(' ')
  end

  # To be overridden by subclasses if they need custom column definitions
  def get_sql_column_string
    get_base_sql_column_string
  end

  def handle_update(record, value)
    raise NotImplementedError, "Subclasses must implement handle_update"
  end
end
