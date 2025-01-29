#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'fileutils'
require 'prettyprint'

class Mine
  DEFAULT_BIN_PATH = "/usr/local/bin/"
  def initialize(opts)
    @opts = opts
    @config_bin_path = opts.fetch(:bin_path, DEFAULT_BIN_PATH).tap do |path|
      path << '/' unless path.end_with?('/')
    end
    @config_path = File.join(ENV['HOME'], '.mine')
    FileUtils.mkdir_p(@config_path)
    @data_file = File.join(@config_path, 'mine.json')
    FileUtils.touch(@data_file) unless File.exist?(@data_file)
    @data = load_data
  end

  def load_data
    return {} unless File.exist?(@data_file) && !File.zero?(@data_file)
    JSON.parse(File.read(@data_file))
  rescue JSON::ParserError => e
    warn "reading json: #{e.message}"
    {}
  end

  def ls
    @data
  end

  def process(file_name)
    file_name += '.rb' unless file_name.end_with?('.rb')
    unless File.exist?(file_name)
      warn "no file with that name"
      return
    end
    puts "making #{file_name} executable"
    FileUtils.chmod("+x", file_name)
    without_ext = File.basename(file_name, File.extname(file_name))
    cmd = "sudo cp #{file_name} #{File.join("#{@config_bin_path}#{without_ext}")}"
    puts "copying to #{@config_bin_path}"
    system cmd
    if @opts[:desc]
      @data[without_ext] = @opts[:desc]
      File.write(@data_file, JSON.pretty_generate(@data))
    end
  end
end

def usage
  puts <<~HELP
  usage: mine [your_ruby_file.rb] [options]

  make a ruby file executable and copy to /usr/local/bin.
  run without argument to see a list of your custom ruby executables

  options:
      -h,      --help               this help
      -d=DESC, --description=DESC   add description of bin
      -b=PATH, --bin-path=PATH      custom path to binary
  HELP
end

options = {}
OptionParser.new do |opts|
  opts.on("-h", "--help", "display help") { usage; exit 0 }
  opts.on("-b=PATH", "--bin-path=PATH", "custom path to binary") { |p| options[:bin_path] = p }
  opts.on("-d=DESC", "--description=DESC", "add description") { |d| options[:desc] = d }
end.parse!

m = Mine.new(options)
if ARGV.empty?
  data = m.ls
  puts data == {} ? 'no data found' : JSON.pretty_generate(data)
  exit 0
else
  m.process(ARGV[0])
end
