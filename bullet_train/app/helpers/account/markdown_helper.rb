module Account::MarkdownHelper
  def markdown(string)
    if defined?(Commonmarker.to_html)
      Commonmarker.to_html(string, options: {
        extensions: {header_ids: true},
        plugins: {syntax_highlighter: {theme: "InspiredGitHub"}},
        render: {width: 120, unsafe: true}
      }).gsub(/&lt;(\/)?script/,'<\\1script').html_safe
      # force script tags to be rendered, for some reason unsafe: true doesn't ignore script tags
      # only the first opening "<" needs re-replacing as the tailing ">" doesn't get replaced by the safety check
    else
      CommonMarker.render_html(string, :UNSAFE, [:table]).html_safe
    end
  end
end
