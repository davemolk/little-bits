#!/usr/bin/env ruby

require 'tmpdir'
require 'fileutils'
require 'uri'

REPO_URL = 'https://github.com/davemolk/little-bits'
repo_name = File.basename(URI.parse(REPO_URL).path, '.git')


files = [
  "kv.rb",
  "lob.rb",
]

Dir.mktmpdir do |tmp_dir|
  Dir.chdir(tmp_dir) do
    system("git clone #{REPO_URL}")
    Dir.chdir(repo_name) do
      files.each do |f|
        unless File.exist?(f)
          puts "file not found: #{f}"
          next
        end

        FileUtils.chmod(0755, f)
        name = File.basename(f, ".rb")

        begin
          FileUtils.copy_file(f, "/usr/local/bin/#{name}")
        rescue Errno::EACCES => e
          puts "permission error when copying #{f}: #{e.message}"
        end
      end
    end
  end
end
