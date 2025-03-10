# Example:
#
# setting = {
#   name: "Movies",
#   slug: "movies",
#   fields: [
#     { name: "title", type: "string" },
#     { name: "poster", type: "upload", relation_to: "media" },
#   ],
# }
#
# Query:
# SELECT movies.*,
#        poster.id AS __poster_id
#        poster.alt as __poster_alt
#        poster.width as __poster_width
#        poster.height as __poster_height
# FROM moves
# WHERE movies.id = ?;
#
# Returns:
# movie = {
#   title: "Example title",
#   poster: {
#     id: 1,
#     alt: "Example text",
#     width: 400
#     height: 300,
#   }
# }

def nested_query(all_collections:, collection:, id:, db:)
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
  puts "--------------------"
  puts query_str
  puts "---"
  p query_values
  puts "--------------------"
end
