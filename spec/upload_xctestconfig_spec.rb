
describe "upload_xctestconfig" do

  let (:app) do
    RunLoop::App.new(IDM::Resources.instance.test_app(:palisade_arm))
  end

  let (:runner) do
    RunLoop::App.new(IDM::Resources.instance.test_app(:palisade_runner_arm))
  end

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
            context "#{device.name} (#{device.version.to_s})" do
              it "installs .xctestconfig, writes .xctestconfig to a file, and prints info" do
                args = ["upload-xctestconf",
                        app.path,
                        runner.path,
                        "--device-id", device.udid]
                hash = IDM.shell(args)

                hash[:out].split("\n").each { |line| puts line }

                expect(hash[:exit_status]).to be == IDM.exit_status(:success)
                out = hash[:out]
                expect(out[/#{app.bundle_identifier}/]).to be_truthy
                session_id = out[/[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}/]
                expect(session_id).to be_truthy

                test_bundle_name = runner.executable_name.split("-")[0]

                testconfig = File.join("xctestconfig",
                                       "#{test_bundle_name}-#{session_id}.xctestconfiguration")
                puts testconfig

                expect(File.exist?(testconfig)).to be_truthy
              end
            end
          end
        end
      end
    end
  end
end
