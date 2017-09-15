
describe "launch-simulator" do

  let(:device) { IDM::Resources.instance.default_simulator }
  let(:udid) { device.udid }
  let(:app) { RunLoop::App.new(IDM::Resources.instance.test_app(:x86)) }
  let(:core_sim) { RunLoop::CoreSimulator.new(device, app) }

  before do
    RunLoop::CoreSimulator.quit_simulator
  end

  it "launches the simulator indicated by --device-id" do
    args = ["launch-simulator", "--device-id", udid]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:success)

    hash = core_sim.send(:running_simulator_details)
    expect(hash[:pid]).to be_truthy
  end
end
