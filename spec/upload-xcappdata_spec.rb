
if IDM::Resources.instance.physical_device_connected?
  describe "upload-xcappdata" do

    let(:device) { IDM::Resources.instance.physical_device }
    let(:app) { IDM::Resources.instance.test_app(:arm) }
    let(:xcappdata) do
      appdata = File.join(IDM::Resources.instance.tmpdir("xcappdata"),
                          "New.xcappdata")

      args = ["generate-xcappdata", appdata]
      hash = IDM.shell(args)
      hash[:out]

      documents = File.join(appdata, "AppData", "Documents")
      FileUtils.mkdir_p(documents)

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

      args = ["upload-xcappdata", app, xcappdata, "--device-id", device.udid]
      hash = IDM.shell(args)

      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
      expect(hash[:out]).to be == ""
    end
  end
end
