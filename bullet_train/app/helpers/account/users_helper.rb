module Account::UsersHelper
  def photo_url_for_active_storage_attachment attachment, options
    size_details = {resize_to_limit: [options[:width], options[:height]]}
    attachment.representation(size_details)
  end

  def profile_photo_for(url: nil, email: nil, first_name: nil, last_name: nil, profile_header: false)
    size_details = profile_header ? {width: 700, height: 200} : {width: 100, height: 100}
    size_details[:crop] = :fill

    if cloudinary_enabled? && !url.blank?
      cl_image_path(url, size_details)
    elsif !url.blank?
      url + "?" + size_details.to_param
    else
      ui_avatar_params(email, first_name, last_name)
    end
  end

  def user_profile_photo_url(user)
    profile_photo_for(
      url: get_photo_url_from(user),
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name
    )
  end

  def membership_profile_photo_url(membership)
    if membership.user
      user_profile_photo_url(membership.user)
    else
      profile_photo_for(
        url: get_photo_url_from(membership),
        email: membership.invitation&.email || membership.user_email,
        first_name: membership.user_first_name,
        last_name: membership.user_last_name
      )
    end
  end

  # TODO: We can do away with these three `profile_header` methods, I'm just
  # leaving them in case we have other developers depending on these methods.
  def profile_header_photo_for(url: nil, email: nil, first_name: nil, last_name: nil)
    if cloudinary_enabled? && !url.blank?
      cl_image_path(url, {width: 700, height: 200, crop: :fill})
    elsif !url.blank?
      url + "?" + {size: 200}.to_param
    else
      ui_avatar_params(email, first_name, last_name)
    end
  end

  def user_profile_header_photo_url(user)
    profile_header_photo_for(
      url: get_photo_url_from(user),
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name
    )
  end

  def membership_profile_header_photo_url(membership)
    if membership.user
      user_profile_header_photo_url(membership.user)
    else
      profile_header_photo_for(
        url: get_photo_url_from(membership),
        email: membership.invitation&.email || membership.user_email,
        first_name: membership.user_first_name,
        last_name: membership.user&.last_name || membership.user_last_name
      )
    end
  end

  def get_photo_url_from(resource)
    photo_method = if resource.is_a?(User)
      :profile_photo
    elsif resource.is_a?(Membership)
      :user_profile_photo
    end

    if cloudinary_enabled?
      resource.send("#{photo_method}_id".to_sym)
    elsif resource.send(photo_method).attached?
      url_for(resource.send(photo_method))
    end
  end

  def ui_avatar_params(email, first_name, last_name)
    background_color = Colorizer.colorize_similarly(email.to_s, 0.5, 0.6).delete("#")
    "https://ui-avatars.com/api/?" + {
      color: "ffffff",
      background: background_color,
      bold: true,
      # email.to_s should not be necessary once we fix the edge case of cancelling an unclaimed membership
      name: "#{first_name&.first || email.to_s[0]} #{last_name&.first || email.to_s[1]}",
      size: 200,
    }.to_param
  end

  def current_membership
    current_user.memberships.where(team: current_team).first
  end
end
