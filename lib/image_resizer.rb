require 'java'

java_import java.awt.Image
java_import java.awt.image.BufferedImage
java_import javax.imageio.ImageIO
java_import javax.imageio.ImageReader
java_import java.awt.Graphics2D
java_import java.awt.AlphaComposite

module ImageResizer

  # from http://stackoverflow.com/a/244177
  def self.resize file_path, height, width, destination_path, preserve_alpha = true
    original = ImageIO.read(java.io.File.new(file_path)).to_java(BufferedImage)
    img_type = ( preserve_alpha ? BufferedImage::TYPE_INT_RGB : BufferedImage::TYPE_INT_ARGB )
    scaled = BufferedImage.new(width, height, img_type)
    g = scaled.createGraphics()
    g.setComposite(AlphaComposite::Src) if preserve_alpha
    g.drawImage(original, 0, 0, width, height, nil)
    g.dispose
    ImageIO.write(scaled, get_format_type(file_path), java.io.File.new(destination_path));
  end

  # from http://stackoverflow.com/a/11447113
  def self.get_format_type path
    image_readers = ImageIO.getImageReaders(ImageIO.createImageInputStream(java.io.File.new(path)))

    while image_readers.hasNext
      return image_readers.next.to_java(ImageReader).getFormatName
    end
  end

end
