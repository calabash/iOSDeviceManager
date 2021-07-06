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

                  puts "Step1"
                  puts app.bundle_identifier
                  puts original_data_path
                  puts udid
                  args = ["download-xcappdata", app.bundle_identifier, original_data_path, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                  original_data = TestHelper.collect_files_in_xcappdata(original_data_path)

                  puts "Step2"
                  puts app.bundle_identifier
                  puts xcappdata
                  puts udid
                  args = ["upload-xcappdata", app.bundle_identifier, xcappdata, "--device-id", udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                  puts "Step3"
                  puts app.bundle_identifier
                  puts uploaded_data_path
                  puts udid
                  args = ["download-xcappdata", app.bundle_identifier, uploaded_data_path, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                  uploaded_data = TestHelper.collect_files_in_xcappdata(uploaded_data_path)
                  puts uploaded_data 
                  puts original_data
                  expect(uploaded_data - original_data).not_to be_empty

                  puts "Step4"
                  puts app.path
                  puts udid
                  args = ["clear-app-data", app.path, udid]
                  hash = IDM.shell(args)
                  expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                  puts "Step5"
                  puts app.bundle_identifier
                  puts cleared_data_path
                  puts udid
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
          end
        end
      end
    end
  end
end
