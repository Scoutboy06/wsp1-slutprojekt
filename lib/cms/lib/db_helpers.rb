require_relative './field'
require_relative './upload_config'
require_relative '../lib'

module DatabaseOperations
  def execute_sql(sql, values = [], debug: false)
    if debug
      puts "\n---- SQL to execute ----"
      puts sql
      puts "---- Values ----"
      p values
    end
    @db.execute(sql, values)
  end

  def build_select_query(slug, id: nil, limit: nil, offset: nil)
    exec_str = "SELECT * FROM #{slug}"
    exec_str << " WHERE id = ?" unless id.nil?
    exec_str << " LIMIT ?" unless limit.nil?
    exec_str << " OFFSET ?" unless offset.nil?
    [exec_str, [id, limit, offset].compact]
  end

  def build_insert_query(slug, fields, data)
    field_names = fields.map(&:name)
    field_values = field.map do |field|
      value = data.fetch(field.name, nil)
      case field.type
      when "boolean"
        value == true ? 1 : 0
      when "password"
        BCrypt::Password.create(value) if value
      else
        value
      end
    end
    exec_str = "INSERT INTO #{slug} (#{field_names.join(', ')}) VALUES (#{(['?'] * field_names.count).join(',')})"
    [exec_str, field_values]
  end

  def build_update_query(slug, fields, data, id_expr: nil, values: [])
    query_parts = ["UPDATE #{slug} SET"]
    set_clauses = fields
      .reject(&:relation_to)
      .map{ |field| "#{field.name} = ?"}
    query_parts << set_clauses.join(', ') if set_clauses.any?

    vals = fields
      .reject(&:relation_to)
      .map { |field| data.fetch(field.name, nil) }

    unless id_expr.nil?
      query_parts << "WHERE id = (#{id_expr})"
      vals.push(*values)
    end

    [query_parts.join("\n"), vals]
  end

  def build_delete_query(slug, id_expr: nil)
    exec_str = "DELETE FROM #{slug}"
    exec_str << " WHERE id = (#{id_expr})" if id_expr
    exec_str
  end
end
