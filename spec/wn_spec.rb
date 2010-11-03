# Load Spec Helper
require File.join(File.expand_path(File.dirname(__FILE__)), 'spec_helper')


describe Webbynode do
  
  describe "initialization" do
    before do
      @wn = Wn::App.new(["init", "2.2.2.2", "test.webbynodeqwerty.com"])
      @wn.stub!(:git_init)
      @wn.stub!(:send)
    end
    
    it "should convert arguments into an array" do
      Wn::App.new('init', '2.2.2.2')
    end
    
    it "should have parse and execute methods" do
      @wn.should respond_to(:parse_command)
      @wn.should respond_to(:execute)
    end
    
    it "should parse the command and arguments" do
      @wn.execute
      @wn.command.should eql("init")
      @wn.options[0].should eql("2.2.2.2")
      @wn.options[1].should eql("test.webbynodeqwerty.com")
    end
    
    it "should extract named parameters to a hash" do
      wn = Wn::App.new("command", "2.2.2.2", "--option=this", "--boolean_option")
      wn.parse_command
      wn.command.should eql("command")
      wn.options.should == ["2.2.2.2"]
      wn.named_options["option"].should == "this"
      wn.named_options["boolean_option"].should == true
    end
        
    it "should display the help text when no arguments are provided" do
      @wn = Wn::App.new
      @wn.should_receive(:log_and_exit).at_least(:once).with(@wn.read_template('help'))
      @wn.should_not_receive(:send)
      @wn.execute
    end
    
    it "should display the help text when a non-existent command is being called" do
      @wn = Wn::App.new("thisdoesnotexist")
      @wn.should_receive(:log_and_exit).at_least(:once).with(@wn.read_template('help'))
      @wn.should_not_receive(:send)
      @wn.execute      
    end
    
    it "should not log and exit if the initial command is provided" do
      @wn.should_not_receive(:log_and_exit)
      @wn.execute
    end
  end

  describe "execution" do
    before do
      @wn = Wn::App.new("init", "2.2.2.2", "test.webbynodeqwerty.com")
    end
    
    it "should execute the given command" do
      @wn.should_receive(:send).with("init")
      @wn.execute
    end
  end
  
  describe "parser" do
    before do
      @wn = Wn::App.new("remote", "ls -la")
      @wn.stub!(:run).and_return(true)
      Net::SSH.stub!(:start).and_return(true)
    end
    
    it "should parse the .git/config file and set the remote_ip" do
      File.should_receive(:open).with(".git/config").and_return(read_fixture("git/config/210.11.13.12"))
      ip = @wn.parse_remote_ip
      ip.should == "210.11.13.12"
    end
    
    it "should parse the options correctly" do
      @wn.parse_command
      @wn.command.should eql("remote")
      @wn.options[0].should eql("ls -la")
    end
    
    it "should parse the .git/config file" do
      File.should_receive(:open).at_least(:once).with(".git/config").and_return(read_fixture('git/config/67.23.79.32'))
      File.should_receive(:open).at_least(:once).with(".pushand").and_return(read_fixture('pushand'))
      @wn.execute
      @wn.remote_ip.should == "67.23.79.32"
    end
    
    it "should parse the .git/config file for another ip" do
      File.should_receive(:open).with(".git/config").and_return(read_fixture('git/config/67.23.79.31'))
      File.should_receive(:open).at_least(:once).with(".pushand").and_return(read_fixture('pushand'))
      @wn.execute
      @wn.remote_ip.should == "67.23.79.31"
    end
    
    it "should parse the application name from the .pushand file" do
      File.should_receive(:open).with(".git/config").and_return(read_fixture('git/config/67.23.79.31'))
      File.should_receive(:open).at_least(:once).with(".pushand").and_return(read_fixture('pushand'))      
      @wn.execute
      @wn.remote_app_name.should eql('test.webbynodeqwerty.com')
    end
  end
  
  describe "commands" do    
    describe "init" do
      before do
        @wn = Wn::App.new("init", "2.2.2.2", "test.webbynodeqwerty.com")
        @wn.stub!(:run)
        @wn.stub!(:create_file)
        @wm.stub!(:log)
      end
      
      it "should be available" do
        @wn.should respond_to(:init)
      end
      
      it "should execute the init command" do
        @wn.should_receive(:send).with("init")
        @wn.execute
      end
      
      it "should check if the .pushand/gitignore files exist. and if the .git directory is present." do
        @wn.should_receive(:file_exists).exactly(:once).with(".gitignore")
        @wn.should_receive(:file_exists).exactly(:once).with(".pushand")
        @wn.should_receive(:dir_exists).at_least(:once).with(".git")
        @wn.execute
      end
      
      it "should initialize git for webbynode" do
        @wn.should_receive(:git_init).with('2.2.2.2', 'test.webbynodeqwerty.com')
        @wn.execute
      end
      
      it "should run 4 git commands" do
        @wn.stub!(:dir_exists).at_least(:once).with(".git").and_return(true)
        @wn.should_receive(:run).at_least(:once).with(/git remote add webbynode git@(.+):(.+)/)
        @wn.should_receive(:run).at_least(:once).with(/git add ./)
        @wn.should_receive(:run).at_least(:once).with(/git commit -m "Initial Webbynode Commit"/)
        @wn.execute
      end
      
      it "should initialize git for webbynode if the .git directory does not exist" do
        @wn.stub!(:dir_exists).with(".git").and_return(false)
        @wn.should_receive(:run).at_least(:once).with("git init")
        @wn.execute
      end
      
      it "should not initialize git for Webbynode if the .git directory already exists" do
        @wn.stub!(:dir_exists).with(".git").and_return(true)
        @wn.should_not_receive(:run).with("git init")
      end
      
    end
        
    describe "push" do
      before do
        @wn = Wn::App.new("push", "2.2.2.2", "test.webbynodeqwerty.com")
        @wn.stub!(:run).and_return(true)
      end
      
      it "should be available" do
        @wn.should respond_to(:push)
      end
      
      it "should check if the .git directory exists" do
        @wn.should_receive(:dir_exists).exactly(:once).with(".git")
        @wn.execute
      end
      
      it "should log a message if the .git directory does not exist" do
        @wn.stub!(:dir_exists).and_return(false)
        @wn.should_receive(:log).with("Not an application or missing initialization. Use 'webbynode init'.")
        @wn.execute
      end
      
      it "should always log a message at least once" do
        @wn.should_receive(:log).with(/Publishing (.+) to Webbynode.../)
        @wn.execute
      end
      
      it "should execute the push command" do
        @wn.should_receive(:run).with("git push webbynode master")
        @wn.execute
      end
    end
    
    describe "remote" do
      before do
        @wn = Wn::App.new("remote", "ls -la")
        @wn.stub!(:run).and_return(true)
        Net::SSH.stub!(:start).and_return(true)
      end
      
      it "should be available" do
        @wn.should respond_to(:remote)
      end
      
      it "should display help instructions if no remote command is given" do
        @wn = Wn::App.new("remote")
        @wn.should_receive(:log_and_exit).at_least(:once).with(@wn.read_template('help'))
        @wn.stub!(:parse_remote_ip)
        @wn.stub!(:parse_remote_app_name)
        @wn.execute
        @wn.options.should be_empty
      end
      
      it do
        @wn.should respond_to(:run_remote_command)
      end
      
      it "should have one option" do
        @wn.stub!(:parse_remote_ip)
        @wn.stub!(:parse_remote_app_name)
        @wn.should_receive(:run_remote_command).with("ls -la")
        @wn.execute
        @wn.options.count.should eql(1)
      end
      
      it "should parse the .git/config folder and retrieve the Webby IP" do
        @wn.stub!(:parse_remote_app_name)
        @wn.stub!(:parse_remote_ip)
        @wn.should_receive(:run_remote_command).with("ls -la")
        @wn.execute
      end
      
      it "should parse the .pushand file and retrieve the remote app name" do
        @wn.should_receive(:run_remote_command).with("ls -la")
        @wn.execute
      end
      
      it "should attempt to execute a command on the Webby using SSH" do
        File.should_receive(:open).with('.git/config').and_return(read_fixture('git/config/210.11.13.12'))
        File.should_receive(:open).with('.pushand').and_return(read_fixture('pushand'))
        @wn.execute
        @wn.remote_ip.should eql('210.11.13.12')
        @wn.remote_app_name.should eql('test.webbynodeqwerty.com')        
      end
      
    end
    
    describe "addkey" do
      def create_command(_options=[], _named_options={})
        kls = Class.new do
          include Wn::Commands
        end
        
        kls.send(:define_method, :options) do
          _options.is_a?(Array) ? _options : [_options]
        end
        
        kls.send(:define_method, :named_options) do
          _named_options
        end

        kls.new
      end
      
      it "should be valid" do
        Wn::App.new("addkey").respond_to?(:addkey).should == true
      end
      
      describe "when key is present" do
        it "should copy the key over SSH" do
          cmd = create_command []
          
          File.should_receive(:exists?).with("#{ENV['HOME']}/.ssh/id_rsa.pub").and_return(true)
          File.should_receive(:read).with("#{ENV['HOME']}/.ssh/id_rsa.pub").and_return("mah key")
          cmd.should_receive(:run_remote_command).with('mkdir ~/.ssh 2>/dev/null; chmod 700 ~/.ssh; echo "mah key" >> ~/.ssh/authorized_keys; chmod 644 ~/.ssh/authorized_keys')
          
          cmd.addkey
        end
      end
      
      describe "when key is missing" do
        def set_expectations(cmd, passphrase="")
          File.should_receive(:exists?).with("#{ENV['HOME']}/.ssh/id_rsa.pub").and_return(false)
          cmd.should_receive(:run).with("ssh-keygen -t rsa -N \"#{passphrase}\" -f #{ENV['HOME']}/.ssh/id_rsa.pub")

          File.should_receive(:read).with("#{ENV['HOME']}/.ssh/id_rsa.pub").and_return(passphrase)
          cmd.should_receive(:run_remote_command).with("mkdir ~/.ssh 2>/dev/null; chmod 700 ~/.ssh; echo \"#{passphrase}\" >> ~/.ssh/authorized_keys; chmod 644 ~/.ssh/authorized_keys")
        end
        
        it "should create a key for the user" do
          cmd = create_command []
          set_expectations cmd
          cmd.addkey 
        end
      
        it "should create a key with passprase if provided" do
          cmd = create_command [], { "passphrase" => "hello" }
          set_expectations cmd, "hello"
          cmd.addkey 
        end
      
        it "should allow a passphrase to contain multiple words" do
          cmd = create_command [], { "passphrase" => "hello mommy" }
          set_expectations cmd, "hello mommy"
          cmd.addkey
        end
      end
    end
  end
end