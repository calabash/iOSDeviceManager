
describe "launch-simulator" do

  let(:device) { IDM::Resources.instance.default_simulator }
  let(:udid) { device.udid }
  let(:app) { RunLoop::App.new(IDM::Resources.instance.test_app(:x86)) }
  let(:core_sim) { RunLoop::CoreSimulator.new(device, app) }

  before do
    RunLoop::CoreSimulator.terminate_core_simulator_processes
  end

  it "launches the simulator indicated by --device-id" do
    args = ["launch-simulator", "--device-id", udid]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:success)

    hash = core_sim.send(:running_simulator_details)
    expect(hash[:pid]).to be_truthy
  end

  it "quits running Simlator.app if --device-id is not the same" do
    core_sim.launch_simulator
    hash = core_sim.send(:running_simulator_details)
    expect(hash[:pid]).to be_truthy

    original_pid = hash[:pid]
    other_simulator = IDM::Resources.instance.random_iphone

    args = ["launch-simulator", "--device-id", other_simulator.udid]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:success)

    # Other simulator is running.
    core_sim = RunLoop::CoreSimulator.new(other_simulator, app)
    hash = core_sim.send(:running_simulator_details)
    expect(hash[:pid]).to be_truthy
    expect(hash[:pid]).not_to be == original_pid
  end

  it "does not quit running Simlator.app if --device-id is the same" do
    core_sim.launch_simulator
    hash = core_sim.send(:running_simulator_details)
    expect(hash[:pid]).to be_truthy

    original_pid = hash[:pid]

    args = ["launch-simulator", "--device-id", udid]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:success)

    hash = core_sim.send(:running_simulator_details)
    expect(hash[:pid]).to be == original_pid
  end
end
