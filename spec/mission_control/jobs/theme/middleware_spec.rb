# frozen_string_literal: true

RSpec.describe MissionControl::Jobs::Theme::Middleware do
  let(:html) do
    "<!DOCTYPE html><html><head><title>MC</title></head><body>OK</body></html>"
  end

  def build_app(status: 200, headers: { "content-type" => "text/html" }, body: html, **middleware_opts)
    inner = ->(_env) { [status, headers, [body]] }
    described_class.new(inner, **middleware_opts)
  end

  def request(app, script_name: "", path: "/")
    app.call("SCRIPT_NAME" => script_name, "PATH_INFO" => path)
  end

  it "injects theme and PrismJS assets in correct order" do
    app = build_app(headers: { "content-type" => "text/html", "content-length" => html.bytesize.to_s })
    status, headers, body = request(app, script_name: "/jobs")
    result = body.join

    expect(result).to include('href="/mission_control/css/prism.min.css"')
    expect(result).to include('href="/mission_control/css/theme.min.css"')
    expect(result).to include('src="/mission_control/js/prism.min.js"')
    expect(result).to include('src="/mission_control/js/prism-init.js"')
    expect(result.index("prism.min.css")).to be < result.index("theme.min.css")
    expect(headers["content-length"]).to eq(result.bytesize.to_s)
    expect(status).to eq(200)
  end

  it "does not add content-length when upstream omits it" do
    _, headers, = request(build_app, script_name: "/jobs")

    expect(headers).not_to have_key("content-length")
  end

  it "injects for nested engine paths like /jobs/queues" do
    _, _, body = request(build_app, script_name: "/jobs", path: "/queues")

    expect(body.join).to include(described_class::THEME_CSS)
  end

  it "injects when content-type includes charset" do
    app = build_app(headers: { "content-type" => "text/html; charset=utf-8" })
    _, _, body = request(app, script_name: "/jobs")

    expect(body.join).to include(described_class::THEME_CSS)
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

    expect(body.join).not_to include(described_class::THEME_CSS)
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
    expect(body.join).to include(described_class::THEME_CSS)

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

    expect(body.join).to include(described_class::THEME_CSS)
  end

  it "passes through Turbo Stream responses at /jobs unchanged" do
    app = build_app(headers: { "content-type" => "text/vnd.turbo-stream.html" })
    _, _, body = request(app, script_name: "/jobs")

    expect(body.join).to eq(html)
  end

  it "omits PrismJS when syntax_highlighting is disabled" do
    app = build_app(syntax_highlighting: false)
    _, _, body = request(app, script_name: "/jobs")
    result = body.join

    expect(result).to include('href="/mission_control/css/theme.min.css"')
    expect(result).not_to include("prism.min.js")
    expect(result).not_to include("prism.min.css")
    expect(result).not_to include("prism-init.js")
  end
end
