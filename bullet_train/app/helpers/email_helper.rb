module EmailHelper
  def email_image_tag(image, **)
    image_underscore = image.tr("-", "_")
    unless attachments.inline[image_underscore]
      attachments.inline[image_underscore] = File.read(Rails.root.join("app/assets/images/#{image}"))
    end
    image_tag(attachments.inline[image_underscore].url, **)
  end
end
