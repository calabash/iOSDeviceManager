
describe "kill-simulator" do

  let(:device) { IDM::Resources.instance.default_simulator }
  let(:udid) { device.udid }
  let(:app) { RunLoop::App.new(IDM::Resources.instance.test_app(:x86)) }
  let(:core_sim) { RunLoop::CoreSimulator.new(device, app) }

  before do
    RunLoop::CoreSimulator.quit_simulator
  end

  it "does not fail if simulator is not running" do
    args = ["kill-simulator"]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    expect(hash[:out]).to be == ""
  end

  it "terminates Simulator.app and shuts down all simulators" do
    core_sim.launch_simulator

    args = ["kill-simulator"]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    expect(hash[:out]).to be == ""

    terminated = RunLoop::ProcessWaiter.new("Simulator").wait_for_none
    expect(terminated).to be_truthy
  end

  it "writes an error if --device-id argument is passed" do
    core_sim.launch_simulator

    args = ["kill-simulator", "--device-id", udid]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    expect(
      hash[:out][/This command no longer takes a --device-id argument/]
    ).to be_truthy

    terminated = RunLoop::ProcessWaiter.new("Simulator").wait_for_none
    expect(terminated).to be_truthy
  end
end
