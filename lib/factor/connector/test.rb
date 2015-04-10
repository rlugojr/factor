require 'rspec'
require 'rspec/expectations'
require 'rspec/matchers'
require 'wrong'

module Factor
  module Connector
    module Test

      RSpec::Matchers.define :log do |expected|
        match do |actual|
          begin
            Wrong.eventually do
              actual.logs.any? do |log|
                case expected.class.name
                when 'Hash'
                  status = expected.keys.first.to_s
                  message = expected.values.first
                  log[:type]=='log' && log[:status]==status && log[:message]==message
                when 'String'
                  log[:type]=='log' && log[:message]==expected
                when 'Symbol'
                  log[:type]=='log' && log[:status]==expected.to_s
                when 'NilClass'
                  log[:type]=='log'
                else
                  false
                end
              end
            end
            true
          rescue => ex
            false
          end
        end

        failure_message do
          case expected.class.name
          when 'Hash'
            status = expected.keys.first.to_s
            message = expected.values.first
            "expected #{actual.logs} to log '#{status}' message '#{message}'"
          when 'Symbol'
            "expected #{actual.logs} to log '#{expected}'"
          when 'String'
            "expected #{actual.logs} to log message '#{expected}'"
          when 'NilClass'
            "expected #{actual.logs} to log a message"
          else
            "#{expected.class} is an unrecognizable matcher type"
          end
        end
      end

      RSpec::Matchers.define :respond do |expected|
        match do |actual|
          begin
            Wrong.eventually do
              actual.logs.any? do |log|
                case expected.class.name
                when 'Hash'
                  log[:type]=='response' && log[:data]==expected
                when 'NilClass'
                  log[:type]=='response'
                else
                  false
                end
              end
            end
            true
          rescue => ex
            false
          end
        end

        failure_message do
          case expected.class.name
          when 'Hash'
            "expected #{actual.logs} to respond with data '#{expected}'"
          when 'NilClass'
            "expected #{actual.logs} to respond"
          else
            "#{expected.class} is an unrecognizable matcher type"
          end
        end
      end

      RSpec::Matchers.define :trigger do |expected|
        match do |actual|
          begin
            Wrong.eventually do
              actual.logs.any? do |log|
                case expected.class.name
                when 'Hash'
                  log[:type]=='trigger' && log[:data]==expected
                when 'NilClass'
                  log[:type]=='trigger'
                else
                  false
                end
              end
            end
            true
          rescue => ex
            false
          end
        end

        failure_message do
          case expected.class.name
          when 'Hash'
            "expected #{actual.logs} to respond with data '#{expected}'"
          when 'NilClass'
            "expected #{actual.logs} to respond"
          else
            "#{expected.class} is an unrecognizable matcher type"
          end
        end
      end

      RSpec::Matchers.define :fail do |expected|
        match do |actual|
          begin
            Wrong.eventually do
              actual.logs.any? do |log|
                case expected.class.name
                when 'String'
                  log[:type]=='fail' && log[:message]==expected
                when 'NilClass'
                  log[:type]=='fail'
                else
                  false
                end
              end
            end
            true
          rescue => ex
            false
          end
        end

        failure_message do
          case expected.class.name
          when 'String'
            "expected #{actual.logs} to fail with message '#{expected}'"
          when 'NilClass'
            "expected #{actual.logs} to fail"
          else
            "#{expected.class} is an unrecognizable matcher type"
          end
        end
      end
    end
  end
end