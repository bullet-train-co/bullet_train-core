const path = require('path');
const { execSync } = require("child_process");

const themeStylesheet = execSync(`bundle exec bin/theme tailwind-stylesheet ${process.env.THEME} 2> /dev/null`).toString().trim()
const themeRoot = execSync(`bundle show bullet_train-themes-${process.env.THEME} 2> /dev/null`).toString().trim()
const themeStylesheetsDir = path.resolve(themeRoot, 'app/assets/stylesheets/');

module.exports = {
  resolve: (id, basedir, importOptions) => {
    if (id.startsWith('$ThemeStylesheetsDir')) {
      id = id.replace('$ThemeStylesheetsDir', themeStylesheetsDir);
    } else if (id.startsWith('$ThemeStylesheet')) {
      id = id.replace('$ThemeStylesheet', themeStylesheet);
    }
    return id;
  }
}