module Rys
  module Bundler
    module Helper

      def comment_lines(path, pattern)
        pattern = pattern.source if pattern.respond_to?(:source)
        pattern = /^(\s*)([^#|\n]*#{pattern})/

        count = 0
        content = File.binread(path)
        content.gsub!(pattern) do
          count += 1
          "#{$1}# #{$2}"
        end
        File.open(path, 'wb') { |file| file.write(content) }
        count
      end

    end
  end
end
