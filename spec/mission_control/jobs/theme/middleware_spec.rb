# frozen_string_literal: true

require_relative "../../../support/dummy/config/application"

RSpec.describe MissionControl::Jobs::Theme::Middleware do
  before do
    Dummy::Application.initialize! unless Dummy::Application.initialized?
  end

  let(:html) do
    "<!DOCTYPE html><html><head><title>MC</title></head><body>OK</body></html>"
  end

  def asset_url(logical_path)
    ActionController::Base.helpers.asset_path(logical_path)
  end

  def css_logical(name)
    "mission_control/theme/#{name}.min.css"
  end

  def js_logical(name)
    "mission_control/theme/#{name}.js"
  end

  def stylesheet_tag(logical, scheme: nil)
    media = scheme ? %( media="(prefers-color-scheme: #{scheme})") : ""
    %(<link rel="stylesheet" href="#{asset_url(logical)}"#{media}>)
  end

  def script_tag(logical, extra: nil, nonce: nil)
    extra_attr = extra ? " #{extra}" : ""
    nonce_attr = nonce ? %( nonce="#{nonce}") : ""
    %(<script src="#{asset_url(logical)}"#{extra_attr}#{nonce_attr}></script>)
  end

  def build_config(**overrides)
    MissionControl::Jobs::Theme::Configuration.new.tap do |c|
      overrides.each { |key, value| c.public_send(:"#{key}=", value) }
    end
  end

  def build_app(status: 200, headers: { "content-type" => "text/html" }, body: html, config: build_config, **opts)
    inner = ->(_env) { [status, headers, [body]] }
    described_class.new(inner, config:, **opts)
  end

  def request(app, script_name: "", path: "/", cookie: nil, csp_nonce: nil)
    env = { "SCRIPT_NAME" => script_name, "PATH_INFO" => path }
    env["HTTP_COOKIE"] = "#{MissionControl::Jobs::Theme::Configuration::COOKIE_NAME}=#{cookie}" if cookie
    env["action_dispatch.content_security_policy_nonce"] = csp_nonce if csp_nonce
    app.call(env)
  end

  context "with auto color scheme (default, no cookie)" do
    it "injects both light and dark stylesheets with prefers-color-scheme media queries" do
      app = build_app(headers: { "content-type" => "text/html", "content-length" => html.bytesize.to_s })
      _, headers, body = request(app, script_name: "/jobs")
      result = body.join
      expect(result).to include(
        stylesheet_tag(css_logical("malachite_light"), scheme: "light"),
        stylesheet_tag(css_logical("malachite_dark"), scheme: "dark"),
        stylesheet_tag("mission_control/theme/prism.default.min.css", scheme: "light"),
        stylesheet_tag("mission_control/theme/prism.tomorrow.min.css", scheme: "dark"),
        script_tag(js_logical("prism.min"), extra: "data-manual"),
        script_tag(js_logical("prism-init")),
        %(src="#{asset_url(js_logical("color-scheme-switcher"))}" data-default-color-scheme="auto"),
        'data-cookie-name="mc_jobs_color_scheme"'
      )
      expect(headers["content-length"]).to eq(result.bytesize.to_s)
    end

    it "omits PrismJS when syntax_highlighting is disabled" do
      app = build_app(config: build_config(syntax_highlighting: false))
      _, _, body = request(app, script_name: "/jobs")
      result = body.join
      expect(result).to include(
        stylesheet_tag(css_logical("malachite_light"), scheme: "light"),
        stylesheet_tag(css_logical("malachite_dark"), scheme: "dark"),
        %(src="#{asset_url(js_logical("color-scheme-switcher"))}" data-default-color-scheme="auto")
      )
      expect(result).not_to include("prism")
    end
  end

  context "with explicit color scheme (no cookie)" do
    it "loads only the light variant when configured" do
      app = build_app(config: build_config(color_scheme: :light),
                      headers: { "content-type" => "text/html", "content-length" => html.bytesize.to_s })
      _, headers, body = request(app, script_name: "/jobs")
      result = body.join
      expect(result).to include(
        stylesheet_tag(css_logical("malachite_light")),
        stylesheet_tag("mission_control/theme/prism.default.min.css"),
        script_tag(js_logical("prism.min"), extra: "data-manual"),
        script_tag(js_logical("prism-init")),
        %(src="#{asset_url(js_logical("color-scheme-switcher"))}" data-default-color-scheme="light")
      )
      expect(result).not_to include("malachite_dark", "prism.tomorrow")
      expect(headers["content-length"]).to eq(result.bytesize.to_s)
    end

    it "loads only the dark variant when configured" do
      app = build_app(config: build_config(color_scheme: :dark))
      _, _, body = request(app, script_name: "/jobs")
      result = body.join
      expect(result).to include(
        stylesheet_tag(css_logical("malachite_dark")),
        stylesheet_tag("mission_control/theme/prism.tomorrow.min.css"),
        %(src="#{asset_url(js_logical("color-scheme-switcher"))}" data-default-color-scheme="dark")
      )
      expect(result).not_to include("malachite_light", "prism.default")
    end

    it "omits PrismJS when syntax_highlighting is disabled" do
      app = build_app(config: build_config(color_scheme: :light, syntax_highlighting: false))
      _, _, body = request(app, script_name: "/jobs")
      result = body.join
      expect(result).to include(stylesheet_tag(css_logical("malachite_light")))
      expect(result).not_to include("prism", "malachite_dark")
    end
  end

  context "with cookie-based color scheme override" do
    it "loads only the cookie scheme, overriding auto default" do
      app = build_app
      _, _, body = request(app, script_name: "/jobs", cookie: "dark")
      result = body.join
      expect(result).to include(
        stylesheet_tag(css_logical("malachite_dark")),
        stylesheet_tag("mission_control/theme/prism.tomorrow.min.css"),
        %(src="#{asset_url(js_logical("color-scheme-switcher"))}" data-default-color-scheme="auto")
      )
      expect(result).not_to include("malachite_light", "prism.default", "prefers-color-scheme")
    end

    it "overrides an explicit configured scheme with the cookie value" do
      app = build_app(config: build_config(color_scheme: :light))
      _, _, body = request(app, script_name: "/jobs", cookie: "dark")
      result = body.join
      expect(result).to include(stylesheet_tag(css_logical("malachite_dark")))
      expect(result).not_to include("malachite_light")
    end

    it "ignores invalid cookie values and falls back to default" do
      app = build_app
      _, _, body = request(app, script_name: "/jobs", cookie: "bogus")
      result = body.join
      expect(result).to include(
        stylesheet_tag(css_logical("malachite_light"), scheme: "light"),
        stylesheet_tag(css_logical("malachite_dark"), scheme: "dark")
      )
    end

    it "treats cookie value 'auto' as invalid and falls back to default" do
      app = build_app
      _, _, body = request(app, script_name: "/jobs", cookie: "auto")
      result = body.join
      expect(result).to include(
        stylesheet_tag(css_logical("malachite_light"), scheme: "light"),
        stylesheet_tag(css_logical("malachite_dark"), scheme: "dark")
      )
    end

    it "reads cookie from a multi-cookie header" do
      app = build_app
      env = { "SCRIPT_NAME" => "/jobs", "PATH_INFO" => "/",
              "HTTP_COOKIE" => "session=abc123; mc_jobs_color_scheme=light; other=val" }
      _, _, body = app.call(env)
      result = body.join
      expect(result).to include(stylesheet_tag(css_logical("malachite_light")))
      expect(result).not_to include("malachite_dark")
    end
  end

  context "with CSP nonce" do
    it "adds nonce from env to script tags but not stylesheet links, and updates content-length" do
      app = build_app(headers: { "content-type" => "text/html", "content-length" => html.bytesize.to_s })
      _, headers, body = request(app, script_name: "/jobs", csp_nonce: "test123")
      result = body.join

      switcher_url = asset_url(js_logical("color-scheme-switcher"))
      switcher_attrs = 'data-default-color-scheme="auto" data-cookie-name="mc_jobs_color_scheme" nonce="test123"'
      switcher_fragment = %(src="#{switcher_url}" #{switcher_attrs})
      expect(result).to include(
        script_tag(js_logical("prism.min"), extra: "data-manual", nonce: "test123"),
        script_tag(js_logical("prism-init"), nonce: "test123"),
        switcher_fragment
      )
      expect(result).not_to match(/<link[^>]*nonce/)
      expect(headers["content-length"]).to eq(result.bytesize.to_s)
    end

    it "extracts nonce from csp-nonce meta tag when env key is absent" do
      html_with_meta = '<!DOCTYPE html><html><head><meta name="csp-nonce" content="xBf3+9/Rq=">' \
                       "<title>MC</title></head><body>OK</body></html>"
      app = build_app(body: html_with_meta)
      _, _, body = request(app, script_name: "/jobs")

      expect(body.join).to include('nonce="xBf3+9/Rq="')
    end

    it "prefers env nonce over csp-nonce meta tag" do
      html_with_meta = '<!DOCTYPE html><html><head><meta name="csp-nonce" content="fromMeta">' \
                       "<title>MC</title></head><body>OK</body></html>"
      app = build_app(body: html_with_meta)
      result = request(app, script_name: "/jobs", csp_nonce: "fromEnv").last.join

      expect(result).to include('nonce="fromEnv"')
      expect(result).not_to include('nonce="fromMeta"')
    end

    it "omits nonce attribute when no nonce source is available" do
      _, _, body = request(build_app, script_name: "/jobs")

      expect(body.join).not_to include("nonce")
    end
  end

  context "with color_scheme_switcher disabled" do
    it "omits the color-scheme-switcher script" do
      app = build_app(config: build_config(color_scheme_switcher: false))
      _, _, body = request(app, script_name: "/jobs")

      expect(body.join).not_to include("color-scheme-switcher")
    end
  end

  it "does not add content-length when upstream omits it" do
    _, headers, = request(build_app, script_name: "/jobs")

    expect(headers).not_to have_key("content-length")
  end

  it "injects for nested engine paths like /jobs/queues" do
    _, _, body = request(build_app, script_name: "/jobs", path: "/queues")

    expect(body.join).to include("malachite_light")
  end

  it "injects when content-type includes charset" do
    app = build_app(headers: { "content-type" => "text/html; charset=utf-8" })
    _, _, body = request(app, script_name: "/jobs")

    expect(body.join).to include("malachite_light")
  end

  it "passes through non-matching paths unchanged" do
    _, _, body = request(build_app, path: "/admin")
    expect(body.join).to eq(html)

    _, _, body = request(build_app, path: "/jobsxyz")
    expect(body.join).to eq(html)
  end

  it "passes through responses without content-type header unchanged" do
    app = build_app(headers: {}, body: html)
    _, _, body = request(app, script_name: "/jobs")

    expect(body.join).to eq(html)
  end

  it "passes through non-HTML content types at /jobs unchanged" do
    app = build_app(headers: { "content-type" => "application/json" }, body: '{"ok":true}')
    _, _, body = request(app, script_name: "/jobs")

    expect(body.join).to eq('{"ok":true}')
  end

  it "passes through non-200 responses at /jobs unchanged" do
    app = build_app(status: 302, body: "")
    _, _, body = request(app, script_name: "/jobs")

    expect(body.join).to eq("")
  end

  it "handles body without </head> gracefully (no theme CSS injected)" do
    app = build_app(body: "<html><body>No head</body></html>")
    _, _, body = request(app, script_name: "/jobs")

    expect(body.join).not_to include("malachite_light")
  end

  it "only injects link/script tags — no other HTML modifications" do
    app = build_app(body: '<html><head></head><body><a href="/x">Jobs (5)</a></body></html>')
    _, _, body = request(app, script_name: "/jobs")
    result = body.join

    expect(result).not_to include("mc-tab-count")
    expect(result).to include('<a href="/x">Jobs (5)</a>')
  end

  it "respects a custom mount_path and ignores the default" do
    app = build_app(mount_path: "/admin/jobs")

    _, _, body = request(app, script_name: "/admin/jobs")
    expect(body.join).to include("malachite_light")

    _, _, body = request(app, script_name: "/jobs")
    expect(body.join).to eq(html)
  end

  it "closes the response body after consuming it" do
    body_io = StringIO.new(html)
    inner = ->(_env) { [200, { "content-type" => "text/html" }, body_io] }
    app = described_class.new(inner, config: build_config)

    app.call("SCRIPT_NAME" => "/jobs", "PATH_INFO" => "/")

    expect(body_io).to be_closed
  end

  it "concatenates multi-part response bodies before injecting" do
    parts = ["<html><head>", "</head><body>OK</body></html>"]
    inner = ->(_env) { [200, { "content-type" => "text/html" }, parts] }
    app = described_class.new(inner, config: build_config)
    _, _, body = app.call("SCRIPT_NAME" => "/jobs", "PATH_INFO" => "/")

    expect(body.join).to include("malachite_light")
  end

  it "passes through Turbo Stream responses at /jobs unchanged" do
    app = build_app(headers: { "content-type" => "text/vnd.turbo-stream.html" })
    _, _, body = request(app, script_name: "/jobs")

    expect(body.join).to eq(html)
  end
end
