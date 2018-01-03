
describe "app life cycle (simulator)" do

  module SimAppLSHelper
    require "run_loop"

    def self.uninstall(core_sim)
      if core_sim.app_is_installed?
         core_sim.uninstall_app_and_sandbox
      end
    end

    def self.prepare_for_install_test(core_sim)
       self.uninstall(core_sim)
       RunLoop::CoreSimulator.quit_simulator
    end

    def self.prepare_for_uninstall_test(core_sim)
      RunLoop::CoreSimulator.quit_simulator
      core_sim.install
      core_sim.launch_simulator
    end

    def self.simctl_thinks_app_is_installed?(device, app)
      args = ["xcrun", "simctl", "get_app_container", device.udid, app.bundle_identifier]
      hash = RunLoop::Shell.run_shell_command(args)
      hash[:exit_status] == 0
    end
  end

  let(:device) { IDM::Resources.instance.default_simulator }
  let(:udid) { device.udid }
  let(:app) { RunLoop::App.new(IDM::Resources.instance.test_app(:x86)) }
  let(:core_sim) { RunLoop::CoreSimulator.new(device, app) }

  context "installing apps on simulator" do
    it "installs app on simulator indicated by --device-id" do
      SimAppLSHelper.prepare_for_install_test(core_sim)

      args = ["install", app.path, "--device-id", udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)

      expect(core_sim.app_is_installed?).to be_truthy
    end

    it "updates app if CFBundleVersion is different"
    it "updates app if CFBundleShortVersionString is different"
    it "updates app if both CFBundle versions are different"
    it "updates app if --force flag is passed"
    it "does not update if app is the same"
  end

  context "uninstalling apps on simulator" do
    it "returns an non-zero exit code if app is not installed" do
      args = ["uninstall", "com.example.NotInstalled", "--device-id", udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:failure)
    end

    it "uninstalls app when first arg is a bundle id" do
      SimAppLSHelper.prepare_for_uninstall_test(core_sim)
      expect(core_sim.app_is_installed?).to be_truthy
      expect(SimAppLSHelper.simctl_thinks_app_is_installed?(device, app)).to be_truthy

      args = ["uninstall", app.bundle_identifier, "--device-id", udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)

      expect(core_sim.app_is_installed?).to be_falsey
      expect(SimAppLSHelper.simctl_thinks_app_is_installed?(device, app)).to be_falsey
    end

    it "uninstalls app when first arg is a .app bundle"
  end
end
