const { execSync } = require("child_process");

const themeStylesheetsDir = execSync(`bundle exec bin/theme stylesheets-dir ${process.env.THEME} 2> /dev/null`).toString().trim()
const themeStylesheet = execSync(`bundle exec bin/theme tailwind-stylesheet ${process.env.THEME} 2> /dev/null`).toString().trim()

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