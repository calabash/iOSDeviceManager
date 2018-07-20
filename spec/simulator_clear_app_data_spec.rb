context "clear-app-data command" do
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
      TestHelper.install(udid, app.path)
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
      original_data = TestHelper.collect_files_in_xcappdata(original_data_path)

      args = ["upload-xcappdata", app.bundle_identifier, xcappdata, "--device-id", udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)

      args = ["download-xcappdata", app.bundle_identifier, uploaded_data_path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
      uploaded_data = TestHelper.collect_files_in_xcappdata(uploaded_data_path)
      expect(uploaded_data - original_data).not_to be_empty

      args = ["clear-app-data", app.path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)

      args = ["download-xcappdata", app.bundle_identifier, cleared_data_path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
      cleared_data = TestHelper.collect_files_in_xcappdata(cleared_data_path)
      expect(cleared_data - original_data).to be_empty
    end

    it "doesn't change caches" do
      original_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Original.xcappdata")
      uploaded_data_path = IDM::Resources.instance.tmp_dir("xcappdata/Uploaded.xcappdata")

      args = ["download-xcappdata", app.bundle_identifier, original_data_path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
      original_caches = TestHelper.collect_cache_files_in_xcappdata(original_data_path)

      args = ["clear-app-data", app.bundle_identifier, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)

      args = ["upload-xcappdata", app.bundle_identifier, xcappdata, "--device-id", udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)

      args = ["download-xcappdata", app.bundle_identifier, uploaded_data_path, udid]
      hash = IDM.shell(args)
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
      uploaded_caches = TestHelper.collect_cache_files_in_xcappdata(uploaded_data_path)
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
