# frozen_string_literal: true

RSpec.describe MissionControl::Jobs::Theme::Middleware do
  let(:html) do
    "<!DOCTYPE html><html><head><title>MC</title></head><body>OK</body></html>"
  end

  def build_config(**overrides)
    MissionControl::Jobs::Theme::Configuration.new.tap do |c|
      overrides.each { |key, value| c.public_send(:"#{key}=", value) }
    end
  end

  def build_app(status: 200, headers: { "content-type" => "text/html" }, body: html, **opts)
    inner = ->(_env) { [status, headers, [body]] }
    described_class.new(inner, **opts)
  end

  def request(app, script_name: "", path: "/", cookie: nil)
    env = { "SCRIPT_NAME" => script_name, "PATH_INFO" => path }
    env["HTTP_COOKIE"] = "#{MissionControl::Jobs::Theme::Configuration::COOKIE_NAME}=#{cookie}" if cookie
    app.call(env)
  end

  context "with auto color scheme (default, no cookie)" do
    it "injects both light and dark stylesheets with prefers-color-scheme media queries" do
      app = build_app(headers: { "content-type" => "text/html", "content-length" => html.bytesize.to_s })
      _, headers, body = request(app, script_name: "/jobs")
      result = body.join
      expect(result).to include('malachite_light.min.css" media="(prefers-color-scheme: light)"',
                                'malachite_dark.min.css" media="(prefers-color-scheme: dark)"',
                                'prism.default.min.css" media="(prefers-color-scheme: light)"',
                                'prism.tomorrow.min.css" media="(prefers-color-scheme: dark)"',
                                'src="/mission_control/js/prism.min.js"',
                                'src="/mission_control/js/prism-init.js"',
                                'color-scheme-switcher.js" data-default-color-scheme="auto"',
                                'data-cookie-name="mc_jobs_color_scheme"')
      expect(headers["content-length"]).to eq(result.bytesize.to_s)
    end

    it "omits PrismJS when syntax_highlighting is disabled" do
      app = build_app(config: build_config(syntax_highlighting: false))
      _, _, body = request(app, script_name: "/jobs")
      result = body.join
      expect(result).to include('malachite_light.min.css" media="(prefers-color-scheme: light)"',
                                'malachite_dark.min.css" media="(prefers-color-scheme: dark)"',
                                'color-scheme-switcher.js" data-default-color-scheme="auto"')
      expect(result).not_to include("prism.min.js", "prism.default.min.css",
                                    "prism.tomorrow.min.css", "prism-init.js")
    end
  end

  context "with explicit color scheme (no cookie)" do
    it "loads only the light variant when configured" do
      app = build_app(config: build_config(color_scheme: :light),
                      headers: { "content-type" => "text/html", "content-length" => html.bytesize.to_s })
      _, headers, body = request(app, script_name: "/jobs")
      result = body.join
      expect(result).to include('malachite_light.min.css">',
                                'prism.default.min.css">',
                                'src="/mission_control/js/prism.min.js"',
                                'src="/mission_control/js/prism-init.js"',
                                'color-scheme-switcher.js" data-default-color-scheme="light"')
      expect(result).not_to include("malachite_dark", "prism.tomorrow")
      expect(headers["content-length"]).to eq(result.bytesize.to_s)
    end

    it "loads only the dark variant when configured" do
      app = build_app(config: build_config(color_scheme: :dark))
      _, _, body = request(app, script_name: "/jobs")
      result = body.join
      expect(result).to include('malachite_dark.min.css">',
                                'prism.tomorrow.min.css">',
                                'color-scheme-switcher.js" data-default-color-scheme="dark"')
      expect(result).not_to include("malachite_light", "prism.default")
    end

    it "omits PrismJS when syntax_highlighting is disabled" do
      app = build_app(config: build_config(color_scheme: :light, syntax_highlighting: false))
      _, _, body = request(app, script_name: "/jobs")
      result = body.join
      expect(result).to include('malachite_light.min.css">')
      expect(result).not_to include("prism.min.js", "prism.default.min.css",
                                    "prism.tomorrow.min.css", "prism-init.js",
                                    "malachite_dark")
    end
  end

  context "with cookie-based color scheme override" do
    it "loads only the cookie scheme, overriding auto default" do
      app = build_app
      _, _, body = request(app, script_name: "/jobs", cookie: "dark")
      result = body.join
      expect(result).to include('malachite_dark.min.css">',
                                'prism.tomorrow.min.css">',
                                'color-scheme-switcher.js" data-default-color-scheme="auto"')
      expect(result).not_to include("malachite_light", "prism.default", "prefers-color-scheme")
    end

    it "overrides an explicit configured scheme with the cookie value" do
      app = build_app(config: build_config(color_scheme: :light))
      _, _, body = request(app, script_name: "/jobs", cookie: "dark")
      result = body.join
      expect(result).to include('malachite_dark.min.css">')
      expect(result).not_to include("malachite_light")
    end

    it "ignores invalid cookie values and falls back to default" do
      app = build_app
      _, _, body = request(app, script_name: "/jobs", cookie: "bogus")
      result = body.join
      expect(result).to include('malachite_light.min.css" media="(prefers-color-scheme: light)"',
                                'malachite_dark.min.css" media="(prefers-color-scheme: dark)"')
    end

    it "treats cookie value 'auto' as invalid and falls back to default" do
      app = build_app
      _, _, body = request(app, script_name: "/jobs", cookie: "auto")
      result = body.join
      expect(result).to include('malachite_light.min.css" media="(prefers-color-scheme: light)"',
                                'malachite_dark.min.css" media="(prefers-color-scheme: dark)"')
    end

    it "reads cookie from a multi-cookie header" do
      app = build_app
      env = { "SCRIPT_NAME" => "/jobs", "PATH_INFO" => "/",
              "HTTP_COOKIE" => "session=abc123; mc_jobs_color_scheme=light; other=val" }
      _, _, body = app.call(env)
      result = body.join
      expect(result).to include('malachite_light.min.css">')
      expect(result).not_to include("malachite_dark")
    end
  end

  context "with color_scheme_switcher disabled" do
    it "omits the color-scheme-switcher script" do
      app = build_app(config: build_config(color_scheme_switcher: false))
      _, _, body = request(app, script_name: "/jobs")

      expect(body.join).not_to include("color-scheme-switcher.js")
    end
  end

  it "does not add content-length when upstream omits it" do
    _, headers, = request(build_app, script_name: "/jobs")

    expect(headers).not_to have_key("content-length")
  end

  it "injects for nested engine paths like /jobs/queues" do
    _, _, body = request(build_app, script_name: "/jobs", path: "/queues")

    expect(body.join).to include("malachite_light.min.css")
  end

  it "injects when content-type includes charset" do
    app = build_app(headers: { "content-type" => "text/html; charset=utf-8" })
    _, _, body = request(app, script_name: "/jobs")

    expect(body.join).to include("malachite_light.min.css")
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

    expect(body.join).not_to include("malachite_light.min.css")
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
    expect(body.join).to include("malachite_light.min.css")

    _, _, body = request(app, script_name: "/jobs")
    expect(body.join).to eq(html)
  end

  it "closes the response body after consuming it" do
    body_io = StringIO.new(html)
    inner = ->(_env) { [200, { "content-type" => "text/html" }, body_io] }
    app = described_class.new(inner)

    app.call("SCRIPT_NAME" => "/jobs", "PATH_INFO" => "/")

    expect(body_io).to be_closed
  end

  it "concatenates multi-part response bodies before injecting" do
    parts = ["<html><head>", "</head><body>OK</body></html>"]
    inner = ->(_env) { [200, { "content-type" => "text/html" }, parts] }
    app = described_class.new(inner)
    _, _, body = app.call("SCRIPT_NAME" => "/jobs", "PATH_INFO" => "/")

    expect(body.join).to include("malachite_light.min.css")
  end

  it "passes through Turbo Stream responses at /jobs unchanged" do
    app = build_app(headers: { "content-type" => "text/vnd.turbo-stream.html" })
    _, _, body = request(app, script_name: "/jobs")

    expect(body.join).to eq(html)
  end
end
