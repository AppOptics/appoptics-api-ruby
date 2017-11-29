require 'spec_helper'

module AppOptics
  module Metrics

    describe Connection do

      describe "#api_endpoint" do
        context "when not provided" do
          it "uses default" do
            expect(subject.api_endpoint).to eq('https://api.appoptics.com')
          end
        end

        context "when provided" do
          it "uses provided endpoint" do
            connection = Connection.new(api_endpoint: 'http://test.com/')
            expect(connection.api_endpoint).to eq('http://test.com/')
          end
        end
      end

      describe "#user_agent" do
        context "without an agent_identifier" do
          it "renders standard string" do
            connection = Connection.new(client: Client.new)
            expect(connection.user_agent).to start_with('appoptics-api-ruby')
          end
        end

        context "with an agent_identifier" do
          it "renders agent_identifier first" do
            client = Client.new
            client.agent_identifier('foo', '0.5', 'bar')
            connection = Connection.new(client: client)
            expect(connection.user_agent).to start_with('foo/0.5')
          end
        end

        context "with a custom user agent set" do
          it "uses custom user agent" do
            client = Client.new
            client.custom_user_agent = 'foo agent'
            connection = Connection.new(client: client)
            expect(connection.user_agent).to eq('foo agent')
          end
        end

        # TODO: verify user agent is being sent with rackup test
      end

      describe "network operations" do
        context "when missing client" do
          it "raises exception" do
            expect { subject.get 'metrics' }.to raise_error(NoClientProvided)
          end
        end

        let(:client) do
          client = Client.new
          client.api_endpoint = 'http://127.0.0.1:9296'
          client.authenticate 'bar'
          client
        end

        context "with 400 class errors" do
          it "does not retry" do
            Middleware::CountRequests.reset
            with_rackup('status.ru') do
              expect {
                client.connection.transport.post 'not_found'
              }.to raise_error(NotFound)
              expect {
                client.connection.transport.post 'forbidden'
              }.to raise_error(ClientError)
            end
            expect(Middleware::CountRequests.total_requests).to eq(2) # no retries
          end
        end

        context "with 500 class errors" do
          it "retries" do
            Middleware::CountRequests.reset
            with_rackup('status.ru') do
              expect {
                client.connection.transport.post 'service_unavailable'
              }.to raise_error(ServerError)
            end
            expect(Middleware::CountRequests.total_requests).to eq(4) # did retries
          end

          it "sends consistent body with retries" do
            Middleware::CountRequests.reset
            status = 0
            begin
              with_rackup('status.ru') do
                response = client.connection.transport.post do |req|
                  req.url 'retry_body'
                  req.body = '{"foo": "bar", "baz": "kaboom"}'
                end
              end
            rescue Exception => error
              status = error.response[:status].to_i
            end
            expect(Middleware::CountRequests.total_requests).to eq(4) # did retries
            expect(status).to eq(502) # body is sent for retries
          end
        end
      end
    end

  end
end
