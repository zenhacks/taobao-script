require 'pry'
require 'pathname'
require 'mini_magick'
require 'fileutils'

puts "the source dir:"
SOURCE_DIR = Pathname "#{ENV['HOME']}/Downloads/products-image"
DEST_DIR = Pathname "#{ENV['HOME']}/Downloads/products-dest"

class ImageProcessor
  include MiniMagick

  def initialize(in_path, out_path)
    @in = in_path
    @out = out_path
  end

  def to_all
    to_web
    to_taobao
  end

  def to_web
    # do reflections on image itself with image[:dimensions]
    image = Image.open @in
    image.resize '620x600'
    image.write @out + "web-#{name(image)}"
    puts "saved processed file to #@out web-#{name(image)}"
  end

  def to_taobao
    image = Image.open @in

    image.resize '1240x1200' if image[:width] > 1240

    # print water logo
    logo_height = logo_width = image[:width] * 0.15
    logo = MiniMagick::Image.open(SOURCE_DIR + '0.water-logo.png')
    logo.resize "#{logo_width}x#{logo_height}"
    result = image.composite(logo) do |c|
      c.gravity "SouthEast"
    end

    result.write @out + "taobao-#{name(image)}"
    puts "saved processed file to #@out taobao-#{name(image)}"
  end

  private

  def name(image)
    [image[:dimensions].join('x'), @in.basename.to_s].join('-')
  end
end

def process(path)
  return unless path.extname =~ /png|jpg|jpeg|gif/
  # move up from the 2.export folder
  folder = path.dirname.relative_path_from(SOURCE_DIR).parent
  dest_folder = DEST_DIR + folder

  FileUtils.mkdir_p dest_folder unless dest_folder.exist?

  processor = ImageProcessor.new(path, dest_folder)

  processor.to_all
end


def walk(root_path)
  root_path.children.each do |path|
    if path.directory?
      walk(path)
    else
      process(path) if path.to_s =~ /export/
    end
  end
end

walk(SOURCE_DIR)

system("jpegoptim -vtm80 --strip-all `find #{DEST_DIR}/**/* -name '*.jpg'`")
system("optipng -o5 `find #{DEST_DIR}/**/* -name '*.png'`")
