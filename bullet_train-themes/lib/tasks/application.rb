module BulletTrain
  module Themes
    module Application
      def self.install_theme(theme_name)
        unless theme_name == "light" || Dir.exist?("app/views/themes/#{theme_name}")
          raise "We could not find '#{theme_name}'. Please eject Bullet Train's standard views to your main application first by using `rake bullet_train:themes:light:eject[custom_theme_name_here]`".red
        end

        # Grabs the current theme from
        # def current_theme
        #   :theme_name
        # end
        current_theme_regexp = /(^    :)(.*)/
        current_theme = nil

        new_lines = []
        [
          "./app/helpers/application_helper.rb",
          "./Procfile.dev",
          "./package.json"
        ].each do |file|
          File.open(file, "r") do |f|
            new_lines = f.readlines
            new_lines = new_lines.map do |line|
              # Make sure we get the current theme before trying to replace it in any of the files.
              # We grab it from the first file in the array above.
              current_theme = line.scan(current_theme_regexp).flatten.last if line.match?(current_theme_regexp)

              line.gsub!(/#{current_theme}/, theme_name) unless current_theme.nil?
              line
            end
          end

          File.open(file, "w") do |f|
            f.puts new_lines.join
          end
        end
      end
    end
  end
end
