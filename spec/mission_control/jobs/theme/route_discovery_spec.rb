# frozen_string_literal: true

RSpec.describe MissionControl::Jobs::Theme::RouteDiscovery do
  def stub_route(app_class, path_spec)
    path = instance_double("ActionDispatch::Journey::Path::Pattern", spec: path_spec)
    app_wrapper = instance_double("ActionDispatch::Routing::Mapper::Constraints", app: app_class)
    instance_double("ActionDispatch::Journey::Route", app: app_wrapper, path:)
  end

  def stub_routes(*route_list)
    instance_double("ActionDispatch::Routing::RouteSet", routes: route_list)
  end

  let(:mc_engine) { stub_const("MissionControl::Jobs::Engine", Class.new) }

  it "strips trailing format segment from the path" do
    routes = stub_routes(stub_route(mc_engine, "/admin/jobs(.:format)"))

    expect(described_class.discover(routes)).to eq("/admin/jobs")
  end

  it "strips trailing slash from the path" do
    routes = stub_routes(stub_route(mc_engine, "/jobs/(.:format)"))

    expect(described_class.discover(routes)).to eq("/jobs")
  end

  it "returns FALLBACK when engine is not mounted" do
    mc_engine
    routes = stub_routes(
      stub_route(Class.new, "/other(.:format)")
    )

    expect(described_class.discover(routes)).to eq("/jobs")
  end

  it "returns FALLBACK when routes collection is empty" do
    mc_engine
    expect(described_class.discover(stub_routes)).to eq("/jobs")
  end

  it "returns FALLBACK when engine constant is not defined" do
    hide_const("MissionControl::Jobs::Engine")

    expect(described_class.discover(stub_routes)).to eq("/jobs")
  end

  it "skips routes where app wrapper is nil" do
    route = instance_double("ActionDispatch::Journey::Route", app: nil)
    routes = stub_routes(route, stub_route(mc_engine, "/jobs(.:format)"))

    expect(described_class.discover(routes)).to eq("/jobs")
  end

  it "skips routes that raise NoMethodError (non-standard entries)" do
    bad_route = instance_double("ActionDispatch::Journey::Route")
    allow(bad_route).to receive(:app).and_raise(NoMethodError)

    good_route = stub_route(mc_engine, "/jobs(.:format)")
    routes = stub_routes(bad_route, good_route)

    expect(described_class.discover(routes)).to eq("/jobs")
  end
end
