require "spec_helper"

describe Timber::Probes::RackHTTPContext do
  describe described_class::Middleware do
    before(:each) do
      class PagesPlainController < ActionController::Base
        layout nil

        def index
          Thread.current[:_timber_context] = Timber::CurrentContext.instance.snapshot
          render json: {}
        end

        def method_for_action(action_name)
          action_name
        end
      end

      ::RailsApp.routes.draw do
        get 'pages_plain' => 'pages_plain#index'
      end
    end

    after(:each) do
      Object.send(:remove_const, :PagesPlainController)
    end

    describe "#process" do
      it "should set the context" do
        dispatch_rails_request("/pages_plain")
        http_context = Thread.current[:_timber_context][:http]
        expect(http_context).to be_kind_of(Timber::Contexts::HTTP)
        expect(http_context.method).to eq("GET")
        expect(http_context.path).to eq("/pages_plain")
        expect(http_context.remote_addr).to eq("123.456.789.10")
        expect(http_context.request_id).to_not be_nil
      end
    end
  end
end