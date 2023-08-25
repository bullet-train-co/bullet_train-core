module EmailHelper
  def email_image_tag(image, **)
    image_underscore = image.tr("-", "_")
    attachments.inline[image_underscore] = File.read(Rails.root.join("app/assets/images/#{image}"))
    image_tag(attachments.inline[image_underscore].url, **)
  end
end
