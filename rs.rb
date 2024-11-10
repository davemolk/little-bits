#!/usr/bin/env ruby

require 'tmpdir'
require 'fileutils'
require 'uri'

CANDIDATES = "available.txt"
REPO_URL = 'https://github.com/davemolk/little-bits'
repo_name = File.basename(URI.parse(REPO_URL).path, '.git')

path = File.join(ENV['HOME'], '.rs')
Dir.mkdir(path) unless Dir.exist?(path)

def get_candidates(path)
  if !File.exist?(File.join(path, CANDIDATES))
    warn "no candidates found"
    exit 0
  end
  File.read(File.join(path, CANDIDATES))
end

args = ARGV.map(&:downcase)

if args.empty?
  warn "need to include some names..."
  puts get_candidates(path)
  exit 1
end

if args[0] == 'list'
  puts get_candidates(path)
  exit 0
end

args.map! { |a| !a.end_with?(".rb") ? a.concat(".rb") : a }
puts "updating the following files: #{args}...\n"

Dir.mktmpdir do |tmp_dir|
  Dir.chdir(tmp_dir) do
    system("git clone #{REPO_URL}")
    Dir.chdir(repo_name) do
      # update candidate list
      files = Dir.glob("*.rb")
      File.write(File.join(path, CANDIDATES), files)
      args.each do |f|
        unless File.exist?(f)
          puts "\nfile not found: #{f}"
          next
        end

        FileUtils.chmod(0755, f)
        name = File.basename(f, ".rb")

        begin
          FileUtils.copy_file(f, "/usr/local/bin/#{name}")
        rescue Errno::EACCES => e
          puts "permission error when copying #{f}: #{e.message}"
        end
        puts "\n#{f} has been updated"
      end
    end
  end
end
