require "fileutils"
require "open3"
require "zlib"
require "rubygems/package"

namespace :ops do
  desc "Create a database dump and local storage archive in BACKUP_DIR (private)"
  task backup: :environment do
    directory = Pathname.new(ENV.fetch("BACKUP_DIR")).expand_path
    FileUtils.mkdir_p(directory, mode: 0700)
    name = "homeharbor-#{Rails.env}-#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}"
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    pg_env = { "PGHOST" => config[:host].to_s, "PGPORT" => (config[:port] || 5432).to_s,
      "PGUSER" => config[:username].to_s, "PGPASSWORD" => config[:password].to_s, "PGDATABASE" => config[:database].to_s }
    dump = directory.join("#{name}.dump")
    _, _, status = Open3.capture3(pg_env, "pg_dump", "--format=custom", "--no-owner", "--no-acl", "--file", dump.to_s)
    abort "pg_dump failed; check connection and pg_dump version (credentials omitted)." unless status.success?
    File.chmod(0600, dump)
    archive = directory.join("#{name}-storage.tar.gz")
    storage = Rails.root.join("storage")
    Zlib::GzipWriter.open(archive.to_s) do |gzip|
      Gem::Package::TarWriter.new(gzip) do |tar|
        Dir.glob(storage.join("**/*").to_s).sort.each do |path|
          next unless File.file?(path) && !File.symlink?(path)
          relative = Pathname.new(path).relative_path_from(storage).to_s.tr("\\", "/")
          tar.add_file_simple(relative, 0600, File.size(path)) { |entry| File.open(path, "rb") { |input| IO.copy_stream(input, entry) } }
        end
      end
    end
    File.chmod(0600, archive)
    puts "Backup created: #{dump.basename} and #{archive.basename}. Treat both as private."
  end
end
