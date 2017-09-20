
describe "install (simulator)" do

  module Helper
    require "run_loop"

    def self.uninstall(core_sim)
      if core_sim.app_is_installed?
         core_sim.uninstall_app_and_sandbox
      end
    end

    def self.prepare_sim_for_test(core_sim)
       self.uninstall(core_sim)
       RunLoop::CoreSimulator.quit_simulator
    end
  end

  let(:device) { IDM::Resources.instance.default_simulator }
  let(:udid) { device.udid }
  let(:app) { RunLoop::App.new(IDM::Resources.instance.test_app(:x86)) }
  let(:core_sim) { RunLoop::CoreSimulator.new(device, app) }

  before do

  end

  it "installs app on simulator indicated by --device-id" do
    Helper.prepare_sim_for_test(core_sim)

    args = ["install", app.path, "--device-id", udid]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:success)

    expect(core_sim.app_is_installed?).to be_truthy
  end
end
