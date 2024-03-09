module Account::MarkdownHelper
  def markdown(string)
    Commonmarker.to_html(string, options: {
      extensions: {header_ids: true},
      plugins: {syntax_highlighter: {theme: "InspiredGitHub"}},
      render: {width: 120, unsafe: true}
    }).html_safe
  end
end
