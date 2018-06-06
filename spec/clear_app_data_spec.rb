module DeviceAppHelper
  require "find"
  require "fileutils"

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

  def self.install(udid, bundle_id)
    if !self.is_installed?(udid, bundle_id)
      args = ["install", bundle_id, "--device-id", udid]
      hash = IDM.shell(args)
      if hash[:exit_status] != IDM.exit_status(:success)
        raise "Expected install to pass: #{hash[:out]}"
      end
    end
  end

  def self.collect_files_in_xcappdata(path)
    data = []
    Find.find(path) do |file|
      # Library/Caches path doesn't remove so we'll just ignore it
      next if File.directory?(file) || file.include?("Library/Caches") ||
        file.include?(".com.apple.mobile_container_manager.metadata.plist")
      data << file.split(path + File::SEPARATOR).last
    end
    data
  end

  def self.collect_cache_files_in_xcappdata(path)
    data = []
    Find.find(path) do |file|
      next if File.directory?(file) || !file.include?("Library/Caches")
      data << file.split(path + File::SEPARATOR).last
    end
    data
  end
end

context "clear-app-data command" do
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
                let (:udid) { device.udid }
                let(:xcappdata) { IDM::Resources.instance.xcappdata }

                before(:each) do
                  path = IDM::Resources.instance.tmp_dir("xcappdata")
                  FileUtils.rm_rf(path)
                  DeviceAppHelper.install(udid, app.path)
                end

                it "fails if app isn't installed"  do
                  args = ["clear-app-data", "com.apple.NoSuchApp", udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:false)
                end

                it "replaces .xcappdata bundle with an empty one" do
                  original_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Original.xcappdata")
                  uploaded_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Uploaded.xcappdata")
                  cleared_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Cleared.xcappdata")

                  args = ["download-xcappdata", app.bundle_identifier, original_data_path, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                  original_data = DeviceAppHelper.collect_files_in_xcappdata(original_data_path)

                  args = ["upload-xcappdata", app.bundle_identifier, xcappdata, "--device-id", udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                  args = ["download-xcappdata", app.bundle_identifier, uploaded_data_path, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                  uploaded_data = DeviceAppHelper.collect_files_in_xcappdata(uploaded_data_path)
                  expect(uploaded_data - original_data).not_to be_empty

                  args = ["clear-app-data", app.path, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                  args = ["download-xcappdata", app.bundle_identifier, cleared_data_path, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                  cleared_data = DeviceAppHelper.collect_files_in_xcappdata(cleared_data_path)
                  expect(cleared_data - original_data).to be_empty
                end

                it "doesn't change caches" do
                  original_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Original.xcappdata")
                  uploaded_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Uploaded.xcappdata")

                  args = ["download-xcappdata", app.bundle_identifier, original_data_path, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                  original_caches = DeviceAppHelper.collect_cache_files_in_xcappdata(original_data_path)

                  args = ["clear-app-data", app.bundle_identifier, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                  args = ["upload-xcappdata", app.bundle_identifier, xcappdata, "--device-id", udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                  args = ["download-xcappdata", app.bundle_identifier, uploaded_data_path, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                  uploaded_caches = DeviceAppHelper.collect_cache_files_in_xcappdata(uploaded_data_path)
                  expect(uploaded_caches - original_caches).to be_empty
                end

                it "works when first argument is an application path" do
                  args = ["clear-app-data", app.path, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                end

                it "works when first argument is a bundle identifier" do
                  args = ["clear-app-data", app.bundle_identifier, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                end
              end
            end
          end
        end
      end
    end
  end

  context "simulators" do
    let (:device) { IDM::Resources.instance.default_simulator }
    let (:udid) { device.udid }
    let (:app) do
      path = IDM::Resources.instance
        .test_app(device.physical_device? ? :arm : :x86)
      RunLoop::App.new(path)
    end
    let(:xcappdata) { IDM::Resources.instance.xcappdata }

    before(:each) do |test|
      path = IDM::Resources.instance.tmp_dir("xcappdata")
      FileUtils.rm_rf(path)
      DeviceAppHelper.install(udid, app.path)
    end

    it "fails if app isn't installed"  do
      args = ["clear-app-data", "com.apple.NoSuchApp", udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:false)
    end

    it "replaces .xcappdata bundle with an empty one" do
      original_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Original.xcappdata")
      uploaded_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Uploaded.xcappdata")
      cleared_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Cleared.xcappdata")

      args = ["download-xcappdata", app.bundle_identifier, original_data_path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
      original_data = DeviceAppHelper.collect_files_in_xcappdata(original_data_path)

      args = ["upload-xcappdata", app.bundle_identifier, xcappdata, "--device-id", udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)

      args = ["download-xcappdata", app.bundle_identifier, uploaded_data_path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
      uploaded_data = DeviceAppHelper.collect_files_in_xcappdata(uploaded_data_path)
      expect(uploaded_data - original_data).not_to be_empty

      args = ["clear-app-data", app.path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)

      args = ["download-xcappdata", app.bundle_identifier, cleared_data_path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
      cleared_data = DeviceAppHelper.collect_files_in_xcappdata(cleared_data_path)
      expect(cleared_data - original_data).to be_empty
    end

    it "doesn't change caches" do
      original_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Original.xcappdata")
      uploaded_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Uploaded.xcappdata")

      args = ["download-xcappdata", app.bundle_identifier, original_data_path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
      original_caches = DeviceAppHelper.collect_cache_files_in_xcappdata(original_data_path)

      args = ["clear-app-data", app.bundle_identifier, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)

      args = ["upload-xcappdata", app.bundle_identifier, xcappdata, "--device-id", udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)

      args = ["download-xcappdata", app.bundle_identifier, uploaded_data_path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
      uploaded_caches = DeviceAppHelper.collect_cache_files_in_xcappdata(uploaded_data_path)
      expect(uploaded_caches - original_caches).to be_empty
    end

    it "works when first argument is an application path" do
      args = ["clear-app-data", app.path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    end

    it "works when first argument is a bundle identifier" do
      args = ["clear-app-data", app.bundle_identifier, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    end
  end
end
