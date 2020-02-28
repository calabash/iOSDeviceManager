
describe "set-location" do

  let(:latitude) { "15.1790" }
  let(:longitude) { "-200.1982" }

  before do
    IDM::Resources.instance.terminate_simulator_processes_then_wait
  end

  context "simulators" do
    let(:device) { IDM::Resources.instance.default_simulator }
    let(:udid) { device.udid }
    let(:app) { RunLoop::App.new(IDM::Resources.instance.test_app(:x86)) }
    let(:core_sim) { RunLoop::CoreSimulator.new(device, app) }

    module Helper
      def self.location_mode
        home_dir = RunLoop::Environment.user_home_directory
        plist = File.join(home_dir, "Library", "Preferences",
                          "com.apple.iphonesimulator.plist")
        RunLoop::PlistBuddy.new.plist_read("LocationMode", plist)
      end
    end

    it "sets the location if the Simulator.app is running" do
      core_sim.launch_simulator

      args = ["set-location", "#{latitude},#{longitude}", "--device-id", udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    end

    it "sets the location if the Simulator.app is not running" do
      RunLoop::CoreSimulator.quit_simulator

      args = ["set-location", "#{latitude},#{longitude}", "--device-id", udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    end

    it "there is a way to test that location has been set"
  end
end
