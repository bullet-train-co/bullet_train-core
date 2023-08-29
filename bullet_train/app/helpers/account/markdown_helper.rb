module Account::MarkdownHelper
  def markdown(string)
    if defined?(Commonmarker.to_html)
      Commonmarker.to_html(string, options: {
        extensions: {header_ids: true},
        plugins: {syntax_highlighter: {theme: "InspiredGitHub"}},
        render: {width: 120, unsafe: true}
      }).html_safe
    else
      CommonMarker.render_html(string, :UNSAFE, [:table]).html_safe
    end
  end
end
