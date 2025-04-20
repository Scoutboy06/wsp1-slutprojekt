def count_entries(db:)
  out = {}
  entries = db.execute("SELECT * FROM sqlite_sequence")
  entries.each do |row|
    name = row['name']
    count = row['seq']
    out[name] = count
  end
  out
end
