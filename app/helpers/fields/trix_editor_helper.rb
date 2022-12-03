module Fields::TrixEditorHelper
  TEMPORARY_REPLACEMENT = "https://temp.bullettrain.co/"

  # TODO We should migrate away from this, but I think we'll need to update Super Scaffolding.
  def trix_sanitize(html)
    html_sanitize(html)
  end
end
