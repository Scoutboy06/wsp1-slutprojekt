class Field
  attr_reader :name, :type, :required, :default, :relation_to, :fields, :admin_visible

  def initialize(name:, type:, required: false, default: nil, relation_to: nil, admin_visible: true)
    @name = name
    @type = type
    @required = required
    @default = default
    @relation_to = relation_to
    @admin_visible = admin_visible
  end

  def self.from_hash(hash)
    new(
      name: hash[:name],
      type: hash[:type],
      required: hash[:required] || false,
      default: hash[:default],
      relation_to: hash[:relation_to],
      admin_visible: hash[:admin_visible] == nil ? true : hash[:admin_visible],
    )
  end

  def get_sql_column_string
    parts = []

    parts << @name
    parts << get_sql_type(@type)
    parts << "NOT NULL" if @required
    parts << @default if @default

    out = parts.join(" ")

    if @relation_to
      out << " REFERENCES #{@relation_to}(id)"
      out << " ON DELETE #{@required ? 'CASCACE' : 'SET NULL'}"
    end

    out
  end
end

SQL_TYPES = {
  "number" => "INTEGER",
  "string" => "TEXT",
  "boolean" => "BOOLEAN",
  "upload" => "INTEGER",
  "email" => "TEXT",
  "password" => "TEXT",
}

def get_sql_type(type_str)
  raise "Invalid field type: `#{type_str}`" if SQL_TYPES[type_str].nil?
  SQL_TYPES[type_str]
end
