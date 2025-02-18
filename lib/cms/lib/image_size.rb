class ImageSize
  attr_reader :name, :width, :height, :position

  def initialize(name:, width:, height:, position: nil)
    @name = name
    @width = width
    @height = height
    @position = position
  end

  def self.from_hash(hash)
    new(
      name: hash[:name],
      width: hash[:width],
      height: hash[:height],
      position: hash[:position],
    )
  end
end
