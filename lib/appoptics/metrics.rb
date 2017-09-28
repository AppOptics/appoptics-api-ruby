$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'base64'
require 'forwardable'

require 'metrics/aggregator'
require 'metrics/annotator'
require 'metrics/client'
require 'metrics/collection'
require 'metrics/connection'
require 'metrics/errors'
require 'metrics/persistence'
require 'metrics/queue'
require 'metrics/smart_json'
require 'metrics/util'
require 'metrics/version'

module Appoptics

  # Metrics provides a simple wrapper for the Metrics web API with a
  # number of added conveniences for common use cases.
  #
  # See the {file:README.md README} for more information and examples.
  #
  # @example Simple use case
  #   Appoptics::Metrics.authenticate 'email', 'api_key'
  #
  #   # list current metrics
  #   Appoptics::Metrics.metrics
  #
  #   # submit a metric immediately
  #   Appoptics::Metrics.submit foo: 12712
  #
  #   # fetch the last 10 values of foo
  #   Appoptics::Metrics.get_measurements :foo, count: 10
  #
  # @example Queuing metrics for submission
  #   queue = Appoptics::Metrics::Queue.new
  #
  #   # queue some metrics
  #   queue.add foo: 12312
  #   queue.add bar: 45678
  #
  #   # send the metrics
  #   queue.submit
  #
  # @example Using a Client object
  #   client = Appoptics::Metrics::Client.new
  #   client.authenticate 'email', 'api_key'
  #
  #   # list client's metrics
  #   client.metrics
  #
  #   # create an associated queue
  #   queue = client.new_queue
  #
  #   # queue up some metrics and submit
  #   queue.add foo: 12345
  #   queue.add bar: 45678
  #   queue.submit
  #
  # @note Most of the methods you can call directly on Appoptics::Metrics are
  #   delegated to {Client} and are documented there.
  module Metrics
    extend SingleForwardable

    TYPES = [:counter, :gauge]
    PLURAL_TYPES = TYPES.map { |type| "#{type}s".to_sym }
    MIN_MEASURE_TIME = (Time.now-(3600*24*365)).to_i

    # Most of the singleton methods of Appoptics::Metrics are actually
    # being called on a global Client instance. See further docs on
    # Client.
    #
    def_delegators  :client, :agent_identifier, :annotate,
                    :api_endpoint, :api_endpoint=, :authenticate,
                    :connection, :create_snapshot, :delete_metrics,
                    :faraday_adapter, :faraday_adapter=, :get_composite,
                    :get_measurements, :get_metric, :get_series,
                    :get_snapshot, :get_source, :metrics,
                    :persistence, :persistence=, :persister, :proxy, :proxy=,
                    :sources, :submit, :update_metric, :update_metrics,
                    :update_source

    # The Appoptics::Metrics::Client being used by module-level
    # access.
    #
    # @return [Client]
    def self.client
      @client ||= Appoptics::Metrics::Client.new
    end

  end
end
