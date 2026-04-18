# frozen_string_literal: true

require "rack/builder"
require "rack/mock"
require_relative "../support/dummy/config/application"

RSpec.describe "Theme injection through Rails engine dispatch", type: :request do
  before do
    Dummy::Application.initialize! unless Dummy::Application.initialized?
  end

  it "injects theme assets when requesting a MC::Jobs engine path at the root" do
    response = Rack::MockRequest.new(Dummy::Application).get("/jobs")

    expect(response.status).to eq(200)
    expect(response.body).to include("malachite_light", "malachite_dark")
  end

  it "injects theme assets when requesting a MC::Jobs engine path under a sub-URI prefix" do
    wrapped = Rack::Builder.new do
      map("/internal") { run Dummy::Application }
    end.to_app

    response = Rack::MockRequest.new(wrapped).get("/internal/jobs")

    expect(response.status).to eq(200)
    expect(response.body).to include("malachite_light", "malachite_dark")
  end

  it "does not inject theme assets into non-engine host-app responses" do
    response = Rack::MockRequest.new(Dummy::Application).get("/non_engine")

    expect(response.status).to eq(200)
    expect(response.body).not_to include("malachite")
    expect(response.body).to include("Host")
  end
end
