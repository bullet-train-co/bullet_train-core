module Fields::HtmlEditorHelper
  TEMPORARY_REPLACEMENT = "https://temp.bullettrain.co/"

  def html_sanitize(string)
    return string unless string
    # TODO this is a hack to get around the fact that rails doesn't allow us to add any acceptable protocols.
    string = string.gsub("bullettrain://", TEMPORARY_REPLACEMENT)
    string = sanitize(string, tags: %w[div br strong em b i del a h1 blockquote pre ul ol li], attributes: %w[href])
    # given the limited scope of what we're doing here, this string replace should work.
    # it should also use a lot less memory than nokogiri.
    string = string.gsub(/<a href="#{TEMPORARY_REPLACEMENT}(.*?)\/.*?">(.*?)<\/a>/o, "<span class=\"tribute-reference tribute-\\1-reference\">\\2</span>").html_safe

    # Also, while we're at it ...
    links_target_blank(string).html_safe
  end

  def links_target_blank(body)
    doc = Nokogiri::HTML(body)
    doc.css("a").each do |link|
      link["target"] = "_blank"
      # To avoid window.opener attack when target blank is used
      # https://mathiasbynens.github.io/rel-noopener/
      link["rel"] = "noopener"
    end
    doc.to_s
  end
end
