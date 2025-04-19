require_relative './collection'

class Global < Collection
  def initialize(name:, slug:, fields: [], icon: nil)
    super(name: name, slug: slug, fields: fields, icon: icon)
  end

  def setup_db(db)
    super
    db.execute("INSERT OR IGNORE INTO #{@slug} (id) VALUES (1)")
  end

  def select(*)
    super(id: 1).first
  end

  def nested_select(*args)
    super(*args, id: 1).first
  end

  def update(data:)
    super(id: 1, data: data)
  end
end
