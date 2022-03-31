module Fields::TrixEditorHelper
  TEMPORARY_REPLACEMENT = "https://temp.bullettrain.co/"

  # TODO We should migrate away from this, but I think we'll need to update Super Scaffolding.
  def trix_sanitize(html)
    html_sanitize(html)
  end

  # TODO Confirm there are no references to this anywhere (in other repositories) and remove it.
  def trix_content(body)
    html_sanitize(body)
  end
end
