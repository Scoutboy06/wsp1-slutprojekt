# Example:
#
# ```ruby
# setting = {
#   name: "Movies",
#   slug: "movies",
#   fields: [
#     { name: "title", type: "string" },
#     { name: "poster", type: "upload", relation_to: "media" },
#   ],
# }
# ```
#
# Query:
# ```sql
# SELECT movies.*,
#        poster.id AS __poster_id
#        poster.alt as __poster_alt
#        poster.width as __poster_width
#        poster.height as __poster_height
# FROM movies
# WHERE movies.id = ?;
# ```
#
# Returns:
# ```ruby
# {
#   title: "Example title",
#   poster: {
#     id: 1,
#     alt: "Example text",
#     width: 400
#     height: 300,
#   }
# }
# ```
def nested_select(all_collections:, collection:, id:, db:)
  query_parts = []
  query_values = []

  ### start SELECT ###
  select_parts = []
  select_parts << "#{collection.slug}.*"

  fields_with_relations = collection.fields
    .select { |field| !!field.relation_to }

  for field in fields_with_relations
    # field = { name: "poster", type: "upload", relation_to: "media" }

    field_collection = all_collections.find { |c| c.slug == field.relation_to }

    for col_field in field_collection.fields
      select_parts << "#{field.name}_#{field.relation_to}.#{col_field.name} AS __#{field.name}_#{field.relation_to}_#{col_field.name}"
    end
  end

  query_parts << "SELECT #{select_parts.join(', ')}"
  ### end SELECT ###

  ### start FROM ###
  query_parts << "FROM #{collection.slug}"
  ### end FROM ###

  ### start LEFT JOIN ###
  left_join_parts = []

  for field in fields_with_relations
    # media ON movies.poster = media.id
    left_join_parts << "LEFT JOIN #{field.relation_to} AS #{field.name}_#{field.relation_to} ON #{collection.slug}.#{field.name} = #{field.name}_#{field.relation_to}.id"
  end

  query_parts << left_join_parts.join("\n  ")
  ### end LEFT JOIN ###

  ### start WHERE ###
  unless id.nil?
    query_parts << "WHERE #{collection.slug}.id = ?"
    query_values << id
  end
  ### end WHERE ###

  query_str = query_parts.join("\n  ")

  data = db.execute(query_str, query_values)

  for result_item in data
    for field in fields_with_relations
      field_hash = {}

      field_collection = all_collections.find { |c| c.slug == field.relation_to }

      for col_field in field_collection.fields
        query_name = "__#{field.name}_#{field.relation_to}_#{col_field.name}"
        query_value = result_item[query_name]
        field_hash[col_field.name] = query_value
        result_item.delete(query_name)
      end

      result_item[field.name] = field_hash
    end
  end

  data
end

def nested_update(all_collections:, collection:, values:, id:, db:)
  query_parts = []
  query_values = []
  p values
  # BEGIN TRANSACTION;
  #
  # UPDATE movies
  # SET title = 'Forrest Gump', description = '', tmdb_id = '13-forrest-gump'
  # WHERE id = ?;
  #
  # UPDATE posters
  # SET last_order_date = DATE('now')
  # WHERE id IN (SELECT customer_id FROM orders WHERE order_date < '2024-01-01');
  #
  # COMMIT;

  query_parts << "BEGIN TRANSACTION;\n"

  # 1. The main table

  query_parts << "UPDATE #{collection.slug}"

  set_parts = collection.fields
    .select { |f| f.relation_to.nil? }
    .map do |field|
      query_values << values[field.name]
      "#{field.name} = ?"
    end

  query_parts << "SET #{set_parts.join(', ')}"

  # 2. The sub-tables

  query_parts << "\nCOMMIT;"

  query_str = query_parts.join("\n  ")
  puts "---------------------"
  puts query_str
  puts "----"
  p query_values
  puts "---------------------"
end
