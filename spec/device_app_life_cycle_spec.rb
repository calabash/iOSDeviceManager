
if IDM::Resources.instance.physical_device_attached?
  describe "app life cycle (physical device)" do
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

    let(:device) { IDM::Resources.instance.default_physical_device }
    let(:udid) { device.udid }
    let(:app) do
      path = IDM::Resources.instance.test_app(:arm)
      RunLoop::App.new(path)
    end

    context "install apps on physical devices" do
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
        expect(DeviceAppLCHelper.is_installed?(udid, app.bundle_identifier)).to be_truthy
      end

      it "updates app if CFBundleVersion is different" do
        args = ["install", app.path, "--device-id", udid]
        hash = IDM.shell(args)
        expect(hash[:exit_status]).to be == IDM.exit_status(:success)

        args = ["install", app_dupe.path, "--device-id", udid]
        expect(app.bundle_version).not_to be == app_dupe.bundle_version
        hash = IDM.shell(args)
        expect(hash[:exit_status]).to be == IDM.exit_status(:success)

        expect(DeviceAppLCHelper.is_installed?(udid, app_dupe.bundle_identifier)).to be_truthy
      end

      it "updates app if CFBundleShortVersionString is different" do
        args = ["install", app.path, "--device-id", udid]
        hash = IDM.shell(args)
        expect(hash[:exit_status]).to be == IDM.exit_status(:success)

        args = ["install", app_dupe.path, "--device-id", udid]
        expect(app.marketing_version).not_to be == app_dupe.marketing_version
        hash = IDM.shell(args)
        expect(hash[:exit_status]).to be == IDM.exit_status(:success)

        expect(DeviceAppLCHelper.is_installed?(udid, app_dupe.bundle_identifier)).to be_truthy
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

        expect(DeviceAppLCHelper.is_installed?(udid, app_dupe.bundle_identifier)).to be_truthy
      end

      it "updates app if --force flag is passed" do
        args = ["install", app.path, "--device-id", udid]
        hash = IDM.shell(args)
        expect(hash[:exit_status]).to be == IDM.exit_status(:success)

        hash = IDM.shell(args << "--force")
        expect(hash[:exit_status]).to be == IDM.exit_status(:success)
        expect(DeviceAppLCHelper.is_installed?(udid, app.bundle_identifier)).to be_truthy
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

    context "uninstall apps on physical devices" do
      it "uninstalls app when first arg is a bundle id" do
        args = ["install", app.path, "--device-id", udid]
        hash = IDM.shell(args)
        expect(hash[:exit_status]).to be == IDM.exit_status(:success)
        expect(DeviceAppLCHelper.is_installed?(udid, app.bundle_identifier)).to be_truthy

        args = ["uninstall", app.bundle_identifier, "--device-id", udid]
        hash = IDM.shell(args)
        expect(hash[:exit_status]).to be == IDM.exit_status(:success)
        expect(DeviceAppLCHelper.is_installed?(udid, app.bundle_identifier)).to be_falsey
      end

      it "uninstalls app when first arg is a .app bundle"
    end
  end
end
