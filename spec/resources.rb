
module IDM
  require "singleton"
  require "run_loop"

  def self.exit_status(key)
    case key
    when :success
      0
    when :failure
      1
    when :false
      2
    when :missing_arg
      3
    when :invalid_arg
      4
    when :internal_error
      5
    when :invalid_command
      6
    when :invalid_flag
      7
    when :device_not_found
      8
    when :no_signing_identity
      9
    else
      raise ArgumentError, "Expected a valid key; found #{key}"
    end
  end

  def self.shell(args)
    cmd = [Resources.instance.idm] + args

    timeout = 180
    if RunLoop::Environment.ci?
      timeout = 300
    end

    RunLoop::Shell.run_shell_command(cmd, {log_cmd: true, timeout: timeout})
  end

  class Resources
    include Singleton

    def project_dir
      @project_dir ||= File.expand_path(File.join(File.dirname(__FILE__), ".."))
    end

    def resources_dir
      @resources_dir ||= File.join(project_dir, "Tests", "Resources")
    end

    def idm
      @idm ||= File.join(project_dir, "Products", "iOSDeviceManager")
    end

    def tmp_dir(subdir=nil)
      @tmp_dir ||= File.join(project_dir, "tmp")
      if subdir
        dir = File.join(tmp_dir, subdir)
      else
        dir = @tmp_dir
      end
      FileUtils.mkdir_p(dir)
      dir
    end

    def xcode
      RunLoop::Xcode.new
    end

    def simctl
      RunLoop::Simctl.new
    end

    def default_simulator
      sim_string = RunLoop::Core.default_simulator(xcode)
      simctl.simulators.detect do |sim|
        sim.instruments_identifier == sim_string
      end
    end

    def default_simulator_for_active_xcode
      RunLoop::Simctl.new.simulators.detect do |sim|
        sim.instruments_identifier(xcode) == RunLoop::Core.default_simulator
      end
    end

    def random_iphone
      simctl.simulators.select do |sim|
        sim.name[/iPhone/] &&
          sim.version >= RunLoop::Version.new("10.0") &&
          sim.udid != default_simulator.udid
      end.sample
    end

    def instruments
      RunLoop::Instruments.new
    end

    def physical_devices
      instruments.physical_devices.select do |device|
        device.compatible_with_xcode_version?(instruments.xcode.version)
      end
    end

    def physical_device_connected?
      !physical_devices.empty?
    end

    def test_app(type)
      @test_app_hash ||= Hash.new
      return @test_app_hash[type] if @test_app_hash[type]

      case type
      when :arm
        source = File.join(resources_dir, "arm", "AppStub.app")
        target = File.join(tmp_dir("arm"), "AppStub.app")
      when :x86
        source = File.join(resources_dir, "sim", "AppStub.app")
        target = File.join(tmp_dir("sim"), "AppStub.app")
      when :ipa
        source = File.join(resources_dir, "arm", "AppStub.ipa")
        target = File.join(tmp_dir("arm"), "AppStub.ipa")
      when :palisade_arm
        source = File.join(resources_dir, "arm", "Palisade.app")
        target = File.join(tmp_dir("arm"), "Palisade.app")
      when :palisade_runner_arm
        source = File.join(resources_dir, "arm", "UITests-Runner.app")
        target = File.join(tmp_dir("arm"), "UITests-Runner.app")
      else
        raise ArgumentError, "Unexpected type: #{type}"
      end

      FileUtils.rm_rf(target)
      FileUtils.cp_r(source, target)

      @test_app_hash[type] = target
      target
    end

    def second_test_app(type)
      @second_test_app_hash ||= Hash.new
      return @second_test_app_hash[type] if @second_test_app_hash[type]

      case type
      when :arm
        source = File.join(resources_dir, "arm", "AppStubDupe.app")
        target = File.join(tmp_dir("arm"), "AppStubDupe.app")
      when :x86
        source = File.join(resources_dir, "sim", "AppStubDupe.app")
        target = File.join(tmp_dir("sim"), "AppStubDupe.app")
      when :ipa
        source = File.join(resources_dir, "arm", "AppStubDupe.ipa")
        target = File.join(tmp_dir("arm"), "AppStubDupe.ipa")
      else
        raise ArgumentError, "Expected :arm, :x86, or :ipa, found: #{type}"
      end

      FileUtils.rm_rf(target)
      FileUtils.cp_r(source, target)

      @second_test_app_hash[type] = target
      target
    end

    def with_developer_dir(developer_dir, &block)
      original_developer_dir = ENV['DEVELOPER_DIR']
      begin
        ENV.delete('DEVELOPER_DIR')
        ENV['DEVELOPER_DIR'] = developer_dir
        RunLoop::Simctl.ensure_valid_core_simulator_service
        block.call
      ensure
        ENV['DEVELOPER_DIR'] = original_developer_dir
      end
    end

    def xcode_install_paths
      @xcode_install_paths ||= begin
        min_xcode_version = RunLoop::Version.new("8.3.3")
        Dir.glob('/Users/Shared/Xcode/*/*.app/Contents/Developer').map do |path|
          xcode_version = path[/(\d+\.\d+(\.\d+)?)/]
          if RunLoop::Version.new(xcode_version) >= min_xcode_version
            path
          else
            nil
          end
        end
      end.compact
    end

    def with_xcode_installations(&block)
      xcode_install_paths.each do |developer_directory|
        with_developer_dir(developer_directory) do
          block.call
        end
      end
    end

    def xcappdata
      appdata = File.join(tmp_dir("xcappdata"), "New.xcappdata")
      args = ["generate-xcappdata", appdata]
      hash = IDM.shell(args)

      if hash[:exit_status] != 0
        raise %Q[
Expected generate-xcappdata to exit with 0 found: #{hash[:exit_status]}

#{hash[:out]}

]
      end

      documents = File.join(appdata, "AppData", "Documents")
      FileUtils.mkdir_p(documents)

      path = File.join(documents,
        "#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}.txt")

      File.open(path, "w") do |file|
        file.puts("content")
      end

      hash[:out]
    end
  end
end
