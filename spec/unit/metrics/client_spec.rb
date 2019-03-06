require 'spec_helper'

module AppOptics
  module Metrics

    describe Client do

      describe "#agent_identifier" do
        context "when given a single string argument" do
          it "sets agent_identifier" do
            subject.agent_identifier 'mycollector/0.1 (dev_id:foo)'
            expect(subject.agent_identifier).to eq('mycollector/0.1 (dev_id:foo)')
          end
        end

        context "when given three arguments" do
          it "composes an agent string" do
            subject.agent_identifier('test_app', '0.5', 'foobar')
            expect(subject.agent_identifier).to eq('test_app/0.5 (dev_id:foobar)')
          end

          context "when given an empty string" do
            it "sets to empty" do
              subject.agent_identifier ''
              expect(subject.agent_identifier).to be_empty
            end
          end
        end

        context "when given two arguments" do
          it "raises error" do
            expect { subject.agent_identifier('test_app', '0.5') }.to raise_error(ArgumentError)
          end
        end
      end

      describe "#api_endpoint" do
        it "defaults to metrics" do
          expect(subject.api_endpoint).to eq('https://api.appoptics.com')
        end
      end

      describe "#api_endpoint=" do
        it "sets api_endpoint" do
          subject.api_endpoint = 'http://test.com/'
          expect(subject.api_endpoint).to eq('http://test.com/')
        end

        # TODO:
        # it "should ensure trailing slash"
        # it "should ensure real URI"
      end

      describe "#authenticate" do
        context "when given one argument" do
          it "stores them as email and api_key" do
            subject.authenticate 'api_key'
            expect(subject.api_key).to eq('api_key')
          end
        end
      end

      describe "#connection" do
        it "raises exception without authentication" do
          subject.flush_authentication
          expect { subject.connection }.to raise_error(AppOptics::Metrics::CredentialsMissing)
        end
      end

      describe "#faraday_adapter" do
        it "defaults to Metrics default adapter" do
          Metrics.faraday_adapter = :typhoeus
          expect(Client.new.faraday_adapter).to eq(Metrics.faraday_adapter)
          Metrics.faraday_adapter = nil
        end
      end

      describe "#faraday_adapter=" do
        it "allows setting of faraday adapter" do
          subject.faraday_adapter = :excon
          expect(subject.faraday_adapter).to eq(:excon)
          subject.faraday_adapter = :patron
          expect(subject.faraday_adapter).to eq(:patron)
        end
      end

      describe "#new_queue" do
        it "returns a new queue with client set" do
          queue = subject.new_queue
          expect(queue.client).to eq(subject)
        end
      end

      describe "#persistence" do
        it "defaults to direct" do
          subject.send(:flush_persistence)
          expect(subject.persistence).to eq(:direct)
        end

        it "allows configuration of persistence method" do
          subject.persistence = :fake
          expect(subject.persistence).to eq(:fake)
        end
      end

      describe "#submit" do
        it "persists metrics immediately" do
          subject.authenticate 'foo'
          subject.persistence = :test
          expect(subject.submit(foo: 123)).to be true
          expect(subject.persister.persisted).to eq({gauges: [{name: 'foo', value: 123}]})
        end

        it "tolerates muliple metrics" do
          subject.authenticate 'foo'
          subject.persistence = :test
          expect { subject.submit foo: 123, bar: 456 }.not_to raise_error
          expected = {gauges: [{name: 'foo', value: 123}, {name: 'bar', value: 456}]}
          expect(subject.persister.persisted).to equal_unordered(expected)
        end
      end

      describe "#set_custom_headers" do
        it "adds custom headers" do
          headers = {"Foo-Header" => "bar"}
          subject.custom_headers = headers
          expect(subject.custom_headers).to eq(headers)
        end
      end

    end

  end
end
