
describe "erase-simulator" do

  let(:device) { IDM::Resources.instance.default_simulator }
  let(:udid) { device.udid }
  let(:app) { RunLoop::App.new(IDM::Resources.instance.test_app(:x86)) }
  let(:core_sim) { RunLoop::CoreSimulator.new(device, app) }

  it "writes an error and exits non-zero if udid argument is a physical device"
  it "writes an error and exits non-zero if no simulator with udid can be found"
  it "erases the simulator"
end
