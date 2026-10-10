# A signed-in shopkeeper gets the language stored in shopkeepers.locale (set
# at sign-up and from the profile screen). Requests without a signed-in
# shopkeeper use the language the client prefers in Accept-Language, among
# I18n.available_locales; anything else gets the default (English). iOS sends
# the header from the device's preferred languages, e.g. "ja-JP, en-JP;q=0.9".
#
# Mails queued during the request keep this locale: Active Job stores
# I18n.locale with each job. Mails to a shopkeeper switch to their own
# locale (Shopkeeper#send_*_instructions, AccountsInvitation#send_invite).
#
# This wraps process_action rather than using around_action: rescue_from
# handlers and rate_limit responses run outside the callback chain, and they
# must answer in the client's language too.
module SetLocale
  private

  def process_action(...)
    I18n.with_locale(locale_from_accept_language) { super }
  end

  # Call once the shopkeeper is authenticated. I18n.with_locale above
  # restores the request's locale afterwards.
  def use_locale_of(shopkeeper)
    locale = shopkeeper&.locale&.to_sym
    I18n.locale = locale if I18n.available_locales.include?(locale)
  end

  def locale_from_accept_language
    preferred_languages.each do |language|
      locale = supported_locale(language)
      return locale if locale
    end

    I18n.default_locale
  end

  # "ja-JP" -> :ja; nil when the language is not offered
  def supported_locale(language_tag)
    locale = language_tag.to_s.split("-").first.to_s.downcase.to_sym
    locale if I18n.available_locales.include?(locale)
  end

  # Language tags by descending quality value, header order breaking ties.
  # Tags the client refuses (q=0) or that fail to parse are dropped.
  def preferred_languages
    request.headers["Accept-Language"].to_s.split(",").filter_map.with_index do |entry, index|
      tag, *params = entry.split(";").map(&:strip)
      next if tag.blank?

      q_param = params.find { |param| param.start_with?("q=") }
      quality = q_param ? Float(q_param.delete_prefix("q="), exception: false) : 1.0
      next if quality.nil? || quality <= 0

      [tag.downcase, quality, index]
    end.sort_by { |_, quality, index| [-quality, index] }.map(&:first)
  end
end
