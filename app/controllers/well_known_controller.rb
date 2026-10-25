# The files that let the apps claim the invitation mail's link,
# https://<app.domain>/invitations/<code> (config/settings.yml app_links).
# Each is 404 until its values are set, so the link opens the landing page in
# the browser instead.
class WellKnownController < ApplicationController
  # iOS Universal Links (Apple, "Supporting associated domains"). Apple reads
  # the file without an extension, so the type is set rather than inferred.
  def apple_app_site_association
    app_ids = ConfigSettings.app_links.ios_app_ids
    return head :not_found if app_ids.blank?

    render json: {
      applinks: {
        details: [{appIDs: app_ids, components: [{"/" => "/invitations/*"}]}]
      }
    }, content_type: "application/json"
  end

  # Android App Links (Digital Asset Links)
  def assetlinks
    package = ConfigSettings.app_links.android_package
    fingerprints = ConfigSettings.app_links.android_sha256_cert_fingerprints
    return head :not_found if package.blank? || fingerprints.blank?

    render json: [{
      relation: ["delegate_permission/common.handle_all_urls"],
      target: {namespace: "android_app", package_name: package, sha256_cert_fingerprints: fingerprints}
    }]
  end
end
