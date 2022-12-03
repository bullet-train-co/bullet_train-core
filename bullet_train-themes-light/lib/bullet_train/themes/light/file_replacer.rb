# TODO: We overwrite/edit/create files a lot in Bullet Train,
# so I feel like this and a lot of similar content could go inside its own gem.
module BulletTrain
  module Themes
    module Light
      module FileReplacer
        def self.files_have_same_content?(first_file_name, second_file_name)
          File.open(first_file_name).readlines == File.open(second_file_name).readlines
        end

        # Replaces the old content with a brand new file.
        def self.replace_content(old:, new:)
          File.write(old, File.open(new).readlines.join(""))
        end
      end
    end
  end
end
