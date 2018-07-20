module TestHelper
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
