$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'net/ssh'
require 'highline/import'
require 'pp'

%w[helpers commands api_client io].each do |f|
  require File.join(File.dirname(__FILE__), 'wn', f)
end

module Wn
  VERSION = '0.1.2'
  
  class App
    attr_accessor :input, :command, :options, :named_options
    
    include Wn::Helpers
    include Wn::Commands
    include Wn::ApiClient
    include Wn::Io
    
    # Initializes the Webbynode App
    def initialize(*input)
      @input = input.flatten
      @named_options = {}
      @options = []
    end
    
    # Parses user input (commands)
    # Initial param is the command
    # Other params are named parameters (like 'command --this=param')
    # or options (like 'command param')
    def parse_command
      log_and_exit read_template('help') if @input.empty?
      @command  = @input.shift
      
      while @input.any?
        opt = @input.shift
        
        if opt =~ /^--(\w+)(=("[^"]+"|[\w]+))*/
          name  = $1
          value = $3 ? $3.gsub(/"/, "") : true
          @named_options[name] = value
        else
          @options << opt
        end
      end
    end
    
    # Executes the parsed command
    def execute
      parse_command
      run_command(command)
    end
    
    # Runs the command unless it's nil or doesn't exist
    # If it fails, it will display the help screen
    def run_command(command)
      if command and respond_to?(command)
        send(command)
      else
        log_and_exit read_template('help')
      end
    end
    
  end
end