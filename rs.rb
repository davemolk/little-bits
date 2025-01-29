#!/usr/bin/env ruby

require 'tmpdir'
require 'fileutils'
require 'uri'

CANDIDATES = "available.txt"
REPO_URL = 'https://github.com/davemolk/little-bits'
repo_name = File.basename(URI.parse(REPO_URL).path, '.git')

path = File.join(ENV['HOME'], '.rs')
FileUtils.mkdir_p(path)

work_path = File.join(path, "work.txt")

def get_candidates(path)
  unless File.exist?(File.join(path, CANDIDATES))
    warn "no candidates found"
    exit 0
  end
  File.read(File.join(path, CANDIDATES))
end

def work_files(path)
  if !File.exist?(path)
    warn 'no work file'
    exit 0
  end
  File.read(path).split("\n")
end

def help
  puts <<~HELP
    usage:
      rs list      list out possible candidates (need a previous sync)
      rs work      sync files for work (needs file at ~/.rs/work.txt)
      rs help      this help text :)
  HELP
end


args = ARGV

if args.empty?
  warn "need to include some names..."
  puts get_candidates(path)
  exit 1
end

case args[0]
when 'help', 'h', '-h', '--help' then help; exit 0
when 'list', 'l', '-l', '--list' then puts get_candidates(path); exit 0
when 'all', 'a', '-a', '--all' then args = []
when 'work', 'w', '-w', '--work' then args = work_files(work_path)
end

args.map! { |a| !a.end_with?(".rb") ? a.concat(".rb") : a }
case args.length
when 0 then puts "updating all files in repo"
else
  puts "updating the following files: #{args}...\n"
end

Dir.mktmpdir do |tmp_dir|
  Dir.chdir(tmp_dir) do
    system("git clone #{REPO_URL}")
    Dir.chdir(repo_name) do
      # update candidate list
      files = Dir.glob("*.rb")
      File.write(File.join(path, CANDIDATES), files)
      if args.empty?
        args = files
      end
      args.each do |f|
        unless File.exist?(f)
          warn "ERROR: file not found: #{f}"
          next
        end

        FileUtils.chmod(0755, f)
        name = File.basename(f, ".rb")

        begin
          # FileUtils.copy_file(f, "/usr/local/bin/#{name}")
          system("cp #{f} /usr/local/bin/#{name}") unless name.start_with?("test")
        rescue Errno::EACCES => e
          warn "ERROR: when copying #{f}: #{e.message}"
        end
        puts "#{f} has been updated"
      end
    end
  end
end
