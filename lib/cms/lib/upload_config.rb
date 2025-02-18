require_relative "./image_size"

class UploadConfig
  attr_reader :static_dir, :image_sizes

  def initialize(static_dir:, image_sizes: [])
    @static_dir = static_dir
    @image_sizes = image_sizes
  end

  def self.from_hash(hash)
    new(
      static_dir: hash[:static_dir],
      image_sizes: hash[:image_sizes]&.map { |is| ImageSize.from_hash(is) },
    )
  end
end
