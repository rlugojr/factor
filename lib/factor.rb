# encoding: UTF-8

require 'commander/import'

require 'factor/version'
require 'commands/workflows'
require 'commands/registry'

program :name, 'Factor.io Server'
program :version, Factor::VERSION
program :description, 'Factor.io Server to run workflows'

command 'server' do |c|
  c.syntax = 'factor server [options]'
  c.description = 'Start the Factor.io Server in the current local directory'
  c.option '--log FILE', String, 'Log file path. Default is stdout.'
  c.option '--credentials FILE', String, 'credentials.yml file path.'
  c.option '--connectors FILE', String, 'connectors.yml file path'
  c.option '--path FILE', String, 'Path to workflows'
  c.when_called Factor::Commands::Workflow, :server
end

command 'registry workflows' do |c|
  c.syntax = 'factor registry workflows'
  c.description = 'Get list of available workflow jumpstarts'
  c.when_called Factor::Commands::Registry, :workflows
end

command 'registry connectors' do |c|
  c.syntax = 'factor registry connectors'
  c.description = 'Get list of available connectors'
  c.when_called Factor::Commands::Registry, :connectors
end

command 'registry connector add' do |c|
  c.syntax = 'factor registry add <id>'
  c.description = 'Get list of available connectors'
  c.option '--credentials FILE', String, 'credentials.yml file path.'
  c.option '--connectors FILE', String, 'connectors.yml file path'
  c.when_called Factor::Commands::Registry, :add_connector
end

alias_command 's', 'server'
alias_command 'r', 'registry'