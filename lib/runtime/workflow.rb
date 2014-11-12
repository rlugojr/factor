# encoding: UTF-8

require 'securerandom'
require 'eventmachine'

require 'commands/base'
require 'common/deep_struct'
require 'runtime/service_caller'
require 'runtime/service_address'

module Factor
  # Runtime class is the magic of the server

  class ExecHandler
    attr_accessor :params, :service, :fail_block

    def initialize(service = nil, params = {})
      @service = service
      @params = params
    end

    def on_fail(&block)
      @fail_block = block
    end
  end

  class Workflow
    attr_accessor :name, :description, :id, :instance_id, :connectors, :credentials

    def initialize(connectors, credentials, options={})
      @workflow_spec  = {}
      @workflows      = {}
      @instance_id    = SecureRandom.hex(3)
      @reconnect      = true
      @logger         = options[:logger] if options[:logger]

      @connectors = Factor::Common.flat_hash(connectors)
      @credentials = credentials
    end

    def load(workflow_definition)
      begin
        EM.run do
          instance_eval(workflow_definition)
        end
      rescue Interrupt
      end
    end

    def listen(service_ref, params = {}, &block)
      e = ExecHandler.new(service_ref, params)

      address = Factor::Runtime::ServiceAddress.new(service_ref)
      connector_url = @connectors[address.namespace]

      if !connector_url
        error "Listener '#{address}' not found"
        e.fail_block.call({}) if e.fail_block
      else
        caller = Factor::Runtime::ServiceCaller.new(connector_url)

        caller.on :close do
          error "Listener '#{address}' disconnected"
        end

        caller.on :open do
          info "Listener '#{address}' starting"
        end

        caller.on :retry do
          warn "Listener '#{address}' reconnecting"
        end

        caller.on :error do
          error "Listener '#{address}' dropped the connection"
        end

        caller.on :return do |data|
          success "Listener '#{address}' started"
        end

        caller.on :start_workflow do |data|
          success "Listener '#{address}' triggered"
          block.call(Factor::Common.simple_object_convert(data))
        end

        caller.on :fail do |info|
          error "Listener '#{address}' failed"
          e.fail_block.call(action_response) if e.fail_block
        end

        caller.on :log do |log_info|
          @logger.log log_info[:status], log_info
        end

        caller.listen(address.id,params)
      end
      e
    end

    def workflow(service_ref, &block)
      address = Factor::Runtime::ServiceAddress.new(service_ref)
      @workflows ||= {}
      @workflows[address] = block
    end

    def run(service_ref, params = {}, &block)
      address = Factor::Runtime::ServiceAddress(service_ref)

      e = ExecHandler.new(service_ref, params)
      if address.workflow?
        workflow_address = address.workflow_address
        workflow = @workflows[workflow_address]

        if workflow
          success "Workflow '#{workflow_address}' starting"
          content = Factor::Common.simple_object_convert(params)
          workflow.call(content)
          success "Workflow '#{workflow_address}' started"
        else
          error "Workflow '#{workflow_address}' not found"
          e.fail_block.call({}) if e.fail_block
        end
      else
        connector_url = @connectors[address.namespace]
        caller = Factor::Runtime::ServiceCaller.new(connector_url)

        caller.on :open do
          info "Action '#{address}' starting"
        end

        caller.on :error do
          error "Action '#{address}' dropped the connection"
        end

        caller.on :return do |data|
          success "Action '#{address}' responded"
          caller.close
          block.call(Factor::Common.simple_object_convert(data))
        end

        caller.on :fail do |info|
          error "Action '#{address}' failed"
          e.fail_block.call(action_response) if e.fail_block
        end

        caller.on :log do |log_info|
          @logger.log log_info[:status], log_info
        end

        caller.action(address.id,params)
      end
      e
    end

    def success(message)
      @logger.success message
    end

    def info(message)
      @logger.info message
    end

    def warn(message)
      @logger.warn message
    end

    def error(message)
      @logger.error message
    end
  end
end
