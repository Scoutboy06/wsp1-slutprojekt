require_relative '../models/models'
require_relative '../lib'

module DatabaseOperations
  def execute_sql(sql, values = [], debug: false, db: nil)
    db ||= @db
    throw 'Database not provided' if db.nil?
    if debug
      puts "\n---- SQL to execute ----"
      puts sql
      puts '---- Values ----'
      p values
      puts ''
    end
    db.execute(sql, values)
  end

  def build_select_query(slug, id: nil, limit: nil, offset: nil)
    exec_str = "SELECT * FROM \"#{slug}\""
    exec_str << ' WHERE id = ?' unless id.nil?
    exec_str << ' LIMIT ?' unless limit.nil?
    exec_str << ' OFFSET ?' unless offset.nil?
    [exec_str, [id, limit, offset].compact]
  end

  def build_update_query(slug, fields, data, id:, id_expr: '?')
    query_parts = ["UPDATE \"#{slug}\" SET"]
    set_clauses = fields
                  .reject { |f| f.relation_to || f.type == 'password' }
                  .map { |field| "'#{field.name.gsub("'", "''")}' = ?" }

    vals = fields
           .reject { |f| f.relation_to || f.type == 'password' }
           .map do |field|
      value = data.fetch(field.name, nil)
      value = [true, 'on'].include?(value) ? 1 : 0 if field.type == 'password'
      value
    end

    password_fields_to_update = fields
                                .select do |f|
      f.type == 'password' &&
        data.key?(f.name) &&
        data.fetch(f.name) != ''
    end

    password_fields_to_update.each do |field|
      set_clauses << "#{field.name} = ?"
      values << BCrypt::Password.create(data.fetch(field.name))
    end

    fields_with_relations = fields.select { |f| f.relation_to }
    fields_with_relations.each do |field|
      value = data.fetch(field.name, nil)
      relation_col = CMS::Config.collections.find { |c| c.slug == field.relation_to }
      relation_col.update(
        id: id,
        id_expr: "SELECT #{field.name} FROM #{slug} WHERE id = ?",
        data: value
      )
    end

    query_parts << set_clauses.join(', ') if set_clauses.any?

    query_parts << "WHERE id = (#{id_expr})"
    vals.push(id)

    [query_parts.join("\n"), vals]
  end

  def build_delete_query(slug, id_expr: '?')
    "DELETE FROM #{slug} WHERE id = (#{id_expr})"
  end
end
