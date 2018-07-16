
module DeviceAppLCHelper
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

  def self.uninstall(udid, bundle_id)
    if self.is_installed?(udid, bundle_id)
      args = ["uninstall", bundle_id, "--device-id", udid]
      hash = IDM.shell(args)
      if hash[:exit_status] != IDM.exit_status(:success)
        raise "Expected uninstall to pass: #{hash[:out]}"
      end
    end
  end
end

describe "app life cycle (physical device)" do
  IDM::Resources.instance.xcode_install_paths.each do |developer_dir|
    IDM::Resources.instance.with_developer_dir(developer_dir) do
      # Add a simulator to this list of of devices
      devices = IDM::Resources.instance.physical_devices
      xcode_version = developer_dir[/(\d+\.\d+(\.\d+)?)/]
      if devices.empty?
        it "Xcode #{xcode_version} no compatible devices connected via USB" do
          expect(true).to be == true
        end
      else

        context "#{developer_dir}" do
          # For every connected (compatible) device
          devices.each do |device|
            device_str = %Q['#{device.name} (#{device.version.to_s})']
            # Run these tests
            let(:udid) { device.udid }
            let(:app) do
              path = IDM::Resources.instance.test_app(:arm)
              RunLoop::App.new(path)
            end

            context "app-info" do
              context "when passed a bundle identifier" do
                it "exits non-zero when app is not installed on device"
                it "prints app info to stdout when app is installed on device"
              end

              context "when passed a path to app" do
                it "exits non-zero when app is not installed on device"
                it "prints app info to stdout when app is installed on device"
              end
            end

            context "install app on #{device_str}" do
              let(:app_dupe) do
                path = IDM::Resources.instance.second_test_app(:arm)
                RunLoop::App.new(path)
              end

              before do
                DeviceAppLCHelper.uninstall(udid, app.bundle_identifier)
                DeviceAppLCHelper.uninstall(udid, app_dupe.bundle_identifier)
              end

              it "installs app on device indicated by --device-id" do
                args = ["install", app.path, "--device-id", udid]
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                expect(
                  DeviceAppLCHelper.is_installed?(udid, app.bundle_identifier)
                ).to be_truthy
              end

              it "updates app if CFBundleVersion is different" do
                args = ["install", app.path, "--device-id", udid]
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                args = ["install", app_dupe.path, "--device-id", udid]
                expect(app.bundle_version).not_to be == app_dupe.bundle_version
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                expect(
                  DeviceAppLCHelper.is_installed?(udid, app_dupe.bundle_identifier)
                ).to be_truthy
              end

              it "updates app if CFBundleShortVersionString is different" do
                args = ["install", app.path, "--device-id", udid]
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                args = ["install", app_dupe.path, "--device-id", udid]
                expect(app.marketing_version).not_to be == app_dupe.marketing_version
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                expect(
                  DeviceAppLCHelper.is_installed?(udid, app_dupe.bundle_identifier)
                ).to be_truthy
              end

              it "updates app if both CFBundle versions are different" do
                args = ["install", app.path, "--device-id", udid]
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                args = ["install", app_dupe.path, "--device-id", udid]
                expect(app.bundle_version).not_to be == app_dupe.bundle_version
                expect(app.marketing_version).not_to be == app_dupe.marketing_version
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                expect(
                  DeviceAppLCHelper.is_installed?(udid, app_dupe.bundle_identifier)
                ).to be_truthy
              end

              it "updates app if --force flag is passed" do
                args = ["install", app.path, "--device-id", udid]
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                hash = IDM.shell(args << "--force")
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                expect(
                  DeviceAppLCHelper.is_installed?(udid, app.bundle_identifier)
                ).to be_truthy
                expect(hash[:out].include?("Installed")).to be_truthy
              end

              it "does not update if app is the same" do
                args = ["install", app.path, "--device-id", udid]
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                expect(hash[:out].include?("not reinstalling")).to be_truthy
              end
            end

            context "uninstall apps on #{device_str}" do
              it "uninstalls app when first arg is a bundle id" do
                args = ["install", app.path, "--device-id", udid]
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                expect(
                  DeviceAppLCHelper.is_installed?(udid, app.bundle_identifier)
                ).to be_truthy

                args = ["uninstall", app.bundle_identifier, "--device-id", udid]
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                expect(
                  DeviceAppLCHelper.is_installed?(udid, app.bundle_identifier)
                ).to be_falsey
              end

              it "uninstalls app when first arg is a .app bundle"
            end
          end
        end
      end
    end
  end
end
