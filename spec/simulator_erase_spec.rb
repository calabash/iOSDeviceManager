describe "erase-simulator" do

  let(:device) { IDM::Resources.instance.default_simulator }
  let(:udid) { device.udid }
  let(:app) { RunLoop::App.new(IDM::Resources.instance.test_app(:x86)) }
  let(:core_sim) { RunLoop::CoreSimulator.new(device, app) }

  it "writes an error and exits non-zero if udid argument is a physical device" do
    args = ["erase-simulator", "0dfe68ff5e62f894f409619526e56184cdc76aef"]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:device_not_found)
    expect(hash[:out][/erase-simulator command is only for simulators/]).to be_truthy

  end

  it "writes an error and exits non-zero if no simulator with udid can be found" do
    args = ["erase-simulator", "0EE61DEB-86EB-47F8-B432-61885A4A77AA"]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:device_not_found)
    expect(hash[:out][/could not find a simulator that matches udid/]).to be_truthy
  end

  it "erases the simulator" do
    if !TestHelper.is_installed?(udid, app.path)
      TestHelper.install(udid, app.path)
    end
    expect(core_sim.app_is_installed?).to be_truthy
    args = ["erase-simulator", udid]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    expect(core_sim.app_is_installed?).to be_falsey
  end
end
