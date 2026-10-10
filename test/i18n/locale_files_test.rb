require "test_helper"

# Every message an API client can see must exist in Japanese. With fallbacks on,
# a missing Japanese key silently answers in English, so this compares the
# loaded translations directly instead of going through I18n.t.
class LocaleFilesTest < ActiveSupport::TestCase
  # Scopes the gems contribute (Active Model/Record, Devise, devise_token_auth)
  GEM_SCOPES = %i[errors activerecord devise devise_token_auth].freeze

  def translations(locale)
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    I18n.backend.send(:translations).fetch(locale)
  end

  def flatten(hash, prefix = nil)
    hash.each_with_object({}) do |(key, value), flat|
      path = [prefix, key].compact.join(".")
      value.is_a?(Hash) ? flat.merge!(flatten(value, path)) : flat[path] = value
    end
  end

  def app_en_keys
    flatten(YAML.load_file(Rails.root.join("config/locales/en.yml")).fetch("en")).keys
  end

  def en
    @en ||= flatten(translations(:en))
  end

  def ja
    @ja ||= flatten(translations(:ja))
  end

  def checked_keys
    gem_keys = en.keys.select { |key| GEM_SCOPES.include?(key.split(".").first.to_sym) }
    (app_en_keys + gem_keys).uniq
  end

  def variables(string)
    string.to_s.scan(/%\{(\w+)\}/).flatten.to_set
  end

  test "ja is an available locale" do
    assert_includes I18n.available_locales, :ja
  end

  test "every English message has a Japanese translation" do
    missing = checked_keys.reject { |key| ja.key?(key) }

    assert_empty missing, "Missing Japanese translations:\n#{missing.join("\n")}"
  end

  # A variable only the Japanese text uses would never be passed in. Plural
  # forms may add %{count}: English "one" spells out "1 character".
  test "Japanese translations only use variables the English text provides" do
    unexpected = checked_keys.filter_map do |key|
      next unless ja.key?(key)

      allowed = variables(en[key])
      allowed << "count" if key.end_with?(".one", ".other")
      extra = variables(ja[key]) - allowed
      "#{key}: #{extra.to_a.join(", ")}" if extra.any?
    end

    assert_empty unexpected, "Japanese-only variables:\n#{unexpected.join("\n")}"
  end
end
