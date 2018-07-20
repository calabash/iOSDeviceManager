describe "is-installed" do
  context "physical devices" do
    IDM::Resources.instance.xcode_install_paths.each do |developer_dir|
      IDM::Resources.instance.with_developer_dir(developer_dir) do
        # Add a simulator to this list of of devices
        devices = IDM::Resources.instance.physical_devices
        xcode_version = developer_dir[/(\d+\.\d+(\.\d+)?)/]
        if devices.empty?
          it "Xcode #{xcode_version} no compatible devices connected via USB" do
            expect(true).to be_truthy
          end
        else
          context "#{developer_dir}" do
            let(:app) { RunLoop::App.new(IDM::Resources.instance.test_app(:arm)) }
            # For every connected (compatible) device
            devices.each do |device|
              context "#{device.name} (#{device.version.to_s})" do
                # Run these tests
                let(:udid) { device.udid }

                it "prints true if app is installed" do
                  if device && device != ""
                    args = ["is-installed", "com.apple.Preferences", "--device-id", udid]
                    hash = IDM.shell(args)
                    expect(hash[:out].split($-0).last).to be == "true"
                    expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                  else
                    pending("No physical device is connected")
                    fail
                  end
                end

                it "prints false if app is not installed" do
                  args = ["is-installed", "com.apple.NoSuchApp", "--device-id", udid]
                  hash = IDM.shell(args)
                  expect(hash[:out].split($-0).last).to be == "false"
                  expect(hash[:exit_status]).to be == IDM.exit_status(:false)
                end
              end
            end
          end
        end
      end
    end
  end
end
