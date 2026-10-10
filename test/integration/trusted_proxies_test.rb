require "test_helper"

# The throttles must count the caller, not the Cloudflare edge in front of this
# origin (config/application.rb, config/cloudflare_ips.yml). Rails' rate_limit
# keys on request.remote_ip, which trusted_proxies resolves past the edge.
#
# Asserted through 429s rather than by reading the config back: with the config
# absent everything still "works", it just counts the wrong party. What breaks
# is who gets locked out.
class TrustedProxiesTest < ActionDispatch::IntegrationTest
  # Two Cloudflare edge addresses in different /24s of 172.64.0.0/13.
  TOKYO_EDGE = "172.64.213.30".freeze
  OTHER_EDGE = "172.71.24.21".freeze

  # Two callers, neither of them a Cloudflare address.
  ALICE = "118.241.68.237".freeze
  BOB = "203.0.113.9".freeze

  SIGN_IN = "/shopkeeper_auth/sign_in".freeze

  # Cloudflare sets X-Forwarded-For to the caller; kamal-proxy appends the
  # address it received the connection from, which is Cloudflare's.
  #
  # The email is unique per attempt on purpose: `logins/email` also throttles
  # five per twenty seconds, and reusing one would trip that rule instead.
  def attempt_sign_in(caller_ip:, edge:)
    post SIGN_IN,
      params: {email: "#{SecureRandom.hex(6)}@example.com", password: "wrong-password"},
      headers: {"HTTP_X_FORWARDED_FOR" => "#{caller_ip}, #{edge}",
                "REMOTE_ADDR" => edge}
    response.status
  end

  # `logins/ip` allows five attempts per twenty seconds (ShopkeeperAuth::SessionsController).
  # Counted against the edge, five sign-ins from anyone behind it lock out everybody else behind it.
  test "two callers behind one Cloudflare edge do not share a login bucket" do
    5.times { assert_not_equal 429, attempt_sign_in(caller_ip: ALICE, edge: TOKYO_EDGE) }

    assert_not_equal 429, attempt_sign_in(caller_ip: BOB, edge: TOKYO_EDGE),
      "Bob's first attempt was refused because Alice used the allowance behind the same edge"
  end

  # Brute force protection has to survive the attacker being routed through
  # different edges, which Cloudflare does for them.
  test "one caller is throttled even when routed through two Cloudflare edges" do
    3.times { attempt_sign_in(caller_ip: ALICE, edge: TOKYO_EDGE) }
    2.times { attempt_sign_in(caller_ip: ALICE, edge: OTHER_EDGE) }

    assert_equal 429, attempt_sign_in(caller_ip: ALICE, edge: OTHER_EDGE),
      "the sixth attempt from one caller must be refused however Cloudflare routed it"
  end

  # rate_limit's default `by:` is request.remote_ip, which RemoteIp resolves with
  # trusted_proxies. Rack's own Request#ip ignores trusted_proxies and stops at the edge.
  test "the RemoteIp middleware resolves past the Cloudflare edge to the caller" do
    request = ActionDispatch::Request.new("REMOTE_ADDR" => TOKYO_EDGE, "HTTP_X_FORWARDED_FOR" => "#{ALICE}, #{TOKYO_EDGE}")
    trusted = Rails.application.config.action_dispatch.trusted_proxies

    assert_equal ALICE, ActionDispatch::RemoteIp::GetIp.new(request, false, trusted).to_s
    assert_equal TOKYO_EDGE, request.ip, "Rack's own ip still stops at the edge"
  end

  # Rails already trusts the private range 172.16.0.0/12 (172.16 to 172.31).
  # Cloudflare's 172.64.0.0/13 (172.64 to 172.71) looks covered and is not.
  test "Cloudflare's 172.64.0.0/13 is trusted and Rails' private 172.16.0.0/12 does not cover it" do
    trusted = Rails.application.config.action_dispatch.trusted_proxies

    assert trusted.any? { |proxy| proxy.include?(TOKYO_EDGE) }, "a Cloudflare edge address must be trusted"
    assert_not IPAddr.new("172.16.0.0/12").include?(TOKYO_EDGE),
      "if this ever passes, the private range grew and the near miss stopped being one"
  end

  # `trusted_proxies =` replaces rather than appends, and kamal-proxy reaches the
  # container over a private Docker address, so dropping the defaults would
  # break the hop this exists to see past.
  test "the private and loopback defaults are still trusted" do
    trusted = Rails.application.config.action_dispatch.trusted_proxies

    ["127.0.0.1", "10.1.2.3", "192.168.1.1", "172.17.0.2"].each do |address|
      assert trusted.any? { |proxy| proxy.include?(address) },
        "#{address} is a default Rails trusts, and replacing the list would have dropped it"
    end
  end

  # The half that lives outside the app. kamal-proxy stops forwarding
  # X-Forwarded-For when `ssl:` is set, so without this the caller's address never
  # reaches Rails and every test above still passes while production throttles Cloudflare.
  test "kamal-proxy is told to forward headers, or everything above this is inert" do
    proxy = YAML.safe_load_file(Rails.root.join("config/deploy.yml")).fetch("proxy")

    assert proxy["ssl"], "if ssl is ever removed, re-read kamal's default: forward_headers flips with it"
    assert_equal true, proxy["forward_headers"]
  end

  # Kamal docs: "By default, kamal-proxy will redirect all HTTP requests to HTTPS
  # when SSL is enabled." While Cloudflare reaches the origin over :80 (SSL/TLS
  # mode Flexible, or the residual :80 traffic under Full (strict)) that is an
  # infinite redirect. Asserted as false, not merely "not true": with the key
  # omitted kamal sends no flag and kamal-proxy applies its default.
  test "kamal-proxy is told not to redirect HTTP to HTTPS" do
    proxy = YAML.safe_load_file(Rails.root.join("config/deploy.yml")).fetch("proxy")

    assert_equal false, proxy["ssl_redirect"], "absent is not false here"
  end

  # `ssl: true` would have kamal-proxy run an ACME challenge on :80, which a
  # Cloudflare-only firewall blocks and "Always Use HTTPS" redirects away; it
  # would fail at renewal, not at deploy time.
  test "TLS uses the Cloudflare Origin certificate from secrets" do
    ssl = YAML.safe_load_file(Rails.root.join("config/deploy.yml")).fetch("proxy").fetch("ssl")
    secrets = File.read(Rails.root.join(".kamal/secrets"))

    assert_equal "NATIVEAPPTEMPLATEAPI_ORIGIN_CERT", ssl["certificate_pem"]
    assert_equal "NATIVEAPPTEMPLATEAPI_ORIGIN_KEY", ssl["private_key_pem"]
    assert_match(/^NATIVEAPPTEMPLATEAPI_ORIGIN_CERT=\$\(cat /, secrets, "the certificate must be read from a file")
    assert_match(/^NATIVEAPPTEMPLATEAPI_ORIGIN_KEY=\$\(cat /, secrets, "the key must be read from a file")
  end
end
