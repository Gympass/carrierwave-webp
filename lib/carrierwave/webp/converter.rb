# encoding: utf-8

require 'webp-ffi'

module CarrierWave
  module WebP
    module Converter
      def convert_to_webp(options = {})
        manipulate! do |img|
          img          = yield(img) if block_given?

          ext = File.extname(img.path)
          return img if ['.png', '.jpg', '.jpeg'].exclude?(ext.downcase)

          webp_path    = "#{img.path}.webp"
          rgb_path    = "#{File.dirname(img.path)}/rgb_#{File.basename(img.path)}"
          old_filename = filename

          begin
            ::WebP.encode(img.path, webp_path, options)
          rescue
            `convert -colorspace RGB #{img.path} #{rgb_path}`
            ::WebP.encode(rgb_path, webp_path, options)
          end

          # XXX: Hacks ahead!
          # I can't find any other way to store an alomost exact copy
          # of file for any particular version
          instance_variable_set('@webp', ".webp")

          storage.store! SanitizedFile.new({
            tempfile: webp_path, filename: webp_path,
            content_type: 'image/webp'
          })

          FileUtils.rm(webp_path) rescue nil
          FileUtils.rm(rgb_path) rescue nil

          instance_variable_set('@webp', "")

          img
        end
      end
    end
  end
end
