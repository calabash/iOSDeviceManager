
describe "is-installed" do

  context "simulators" do
    let(:device) { IDM::Resources.instance.default_simulator }
    let(:udid) { device.udid }
    let(:app) { RunLoop::App.new(IDM::Resources.instance.test_app(:x86)) }

    before do
      RunLoop::CoreSimulator.new(device, app).launch_simulator
    end

    it "prints true if app is installed" do
      args = ["is-installed", "com.apple.Preferences", "--device-id", udid]
      hash = IDM.shell(args)
      expect(hash[:out]).to be == "true"
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    end

    it "prints false if app is not installed" do
      args = ["is-installed", "com.apple.NoSuchApp", "--device-id", udid]
      hash = IDM.shell(args)
      expect(hash[:out]).to be == "false"
      expect(hash[:exit_status]).to be == IDM.exit_status(:false)
    end
  end

  if IDM::Resources.instance.physical_device_attached?
    context "physical devices" do
      let(:device) { IDM::Resources.instance.default_physical_device}
      let(:udid) { device.udid }

      it "prints true if app is installed" do
        args = ["is-installed", "com.apple.Preferences", "--device-id", udid]
        hash = IDM.shell(args)
        expect(hash[:out]).to be == "true"
        expect(hash[:exit_status]).to be == IDM.exit_status(:success)
      end

      it "prints false if app is not installed" do
        args = ["is-installed", "com.apple.NoSuchApp", "--device-id", udid]
        hash = IDM.shell(args)
        expect(hash[:out]).to be == "false"
        expect(hash[:exit_status]).to be == IDM.exit_status(:false)
      end
    end
  end
end
