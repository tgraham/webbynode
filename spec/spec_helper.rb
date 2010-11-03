# Require RSpec
require 'spec'

# Load Webbynode Class
require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib', 'wn')

# Set Testing Environment
$testing = true

# Alias the Wn Class Object
Webbynode = Wn


# Helper Methods

# Reads out a file from the fixtures directory
def read_fixture(file)
  File.read(File.join(File.dirname(__FILE__), "fixtures", file))
end

