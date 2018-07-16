module DeviceAppHelper
  def self.is_installed?(udid, bundle_id)
    args = ["is-installed", bundle_id, "--device-id", udid]
    hash = IDM.shell(args)

    if hash[:exit_status] == IDM.exit_status(:success) ||
        hash[:exit_status] == IDM.exit_status(:false)
      hash[:out].split($-0).last == "true"
    else
      raise "Expected is-installed to pass: #{hash[:out]}"
    end
  end

  def self.install(udid, bundle_id)
    if !self.is_installed?(udid, bundle_id)
      args = ["install", bundle_id, "--device-id", udid]
      hash = IDM.shell(args)
      if hash[:exit_status] != IDM.exit_status(:success)
        raise "Expected install to pass: #{hash[:out]}"
      end
    end
  end
end

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
    if !DeviceAppHelper.is_installed?(udid, app.path)
      DeviceAppHelper.install(udid, app.path)
    end
    expect(core_sim.app_is_installed?).to be_truthy
    args = ["erase-simulator", udid]
    hash = IDM.shell(args)
    expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    expect(core_sim.app_is_installed?).to be_falsey
  end
end
