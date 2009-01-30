module ImageOperations
  require 'RMagick'

  def self.get_image(filename)
    Magick::Image.read( filename ).first
  end
  
  def self.is_image?(image)
    image ? (image.columns > 0 ? true : false) : false
  end
  
  def self.scale_down(image, size)
    if image.columns > size or image.rows > size
      if image.columns > image.rows
        scale = size.to_f / image.columns
      else
        scale = size.to_f / image.rows
      end
      
      image.scale!(scale)
    end
    image
  end
  
  def self.shadow( image )
    shadow = image.dup
    shadow.background_color = "#666666"
    shadow.erase!
    shadow.border!(26, 26, "#fafafa")
    shadow = shadow.blur_image(0, 8/2)
    shadow.composite( image, Magick::NorthWestGravity,
                      (shadow.columns - image.columns) / 2 - 4,
                      (shadow.rows    - image.rows) / 2 - 4,
                      Magick::OverCompositeOp
                      ).trim!
  end
  
  def self.thumbnail(image, size)
    thumb = scale_down(image,size)
    thumb = shadow(thumb)
    thumb.format = 'jpg'
    thumb
  end
  
end
