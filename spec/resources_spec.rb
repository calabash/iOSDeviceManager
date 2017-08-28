
describe "resources" do

  context "#device_compatible_with_xcode?" do

    let(:device) { IDM::Resources.instance.default_simulator }
    let(:xcode) { IDM::Resources.instance.xcode }

    it "returns true if major versions are compatible" do
      values = [RunLoop::Version.new("9.0"),
                RunLoop::Version.new("8.0"),
                RunLoop::Version.new("7.0")]
      expect(device).to receive(:version).and_return(*values)
      expect(xcode).to receive(:version).exactly(3).times.and_return(RunLoop::Version.new("7.0"))

      3.times {
        expect(
          IDM::Resources.instance.device_compatible_with_xcode?(device, xcode)
        ).to be_truthy
      }
    end

    it "returns true if major and minor versions are compatible" do
      values = [RunLoop::Version.new("9.0"),
                RunLoop::Version.new("9.1"),
                RunLoop::Version.new("9.2")]
      expect(device).to receive(:version).and_return(*values)
      expect(xcode).to receive(:version).exactly(3).times.and_return(RunLoop::Version.new("7.2"))

      3.times {
        expect(
          IDM::Resources.instance.device_compatible_with_xcode?(device, xcode)
        ).to be_truthy
      }
    end

    it "returns false if minor versions are not compatible" do
      values = [RunLoop::Version.new("9.1"),
                RunLoop::Version.new("9.2"),
                RunLoop::Version.new("9.3")]
      expect(device).to receive(:version).and_return(*values)
      expect(xcode).to receive(:version).exactly(3).times.and_return(RunLoop::Version.new("7.0"))

      3.times {
        expect(
          IDM::Resources.instance.device_compatible_with_xcode?(device, xcode)
        ).to be_falsey
      }
    end

    it "returns false if major versions are not compatible" do
      values = [RunLoop::Version.new("9.0"),
                RunLoop::Version.new("10.0"),
                RunLoop::Version.new("11.0")]
      expect(device).to receive(:version).and_return(*values)
      expect(xcode).to receive(:version).exactly(3).times.and_return(RunLoop::Version.new("6.0"))

      3.times {
        expect(
          IDM::Resources.instance.device_compatible_with_xcode?(device, xcode)
        ).to be_falsey
      }
    end
  end
end
