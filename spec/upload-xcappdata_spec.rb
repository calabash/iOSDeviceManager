
describe "upload-xcappdata" do
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
          let(:app) { IDM::Resources.instance.test_app(:arm) }
          # For every connected (compatible) device
          devices.each do |device|
            context "#{device.name} (#{device.version.to_s})" do
              # Run these tests
              let(:xcappdata) do
                appdata = File.join(IDM::Resources.instance.tmp_dir("xcappdata"),
                                    "New.xcappdata")

                args = ["generate-xcappdata", appdata, "--overwrite",  "1"]
                hash = IDM.shell(args)
                hash[:out]

                documents = File.join(appdata, "AppData", "Documents")
                #FileUtils.mkdir_p(documents)

                path = File.join(documents,
                                 "#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}.txt")
                File.open(path, "w") do |file|
                  file.puts("content")
                end

                hash[:out]
              end

              it "uploads xcappdata" do
                args = ["install", app, "--device-id", device.udid]
                hash = IDM.shell(args)
                expect(hash[:exit_status]).to be == IDM.exit_status(:success)

                args = ["upload-xcappdata", app, xcappdata,
                        "--device-id", device.udid]
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
