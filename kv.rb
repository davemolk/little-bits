#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require 'optparse'

class FileDB
  def initialize(path)
    @file_path = File.join(path, 'db.json')
    FileUtils.touch(@file_path) unless File.exist?(@file_path)
    @data = load_data(@file_path)
  end

  def load_data(path)
    return {} unless File.exist?(path) && !File.zero?(path)

    JSON.parse(File.read(path))
  rescue JSON::ParserError => e
    warn "error reading json, resetting db: #{e.message}"
    {}
  end

  def save
    File.write(@file_path, JSON.pretty_generate(@data))
  rescue StandardError => e
    warn "error saving db: #{e.message}"
    false
  end
  
  def set(key, *values)
    return if key.nil? || key.empty?
    @data[key] = values
    save
  end

  def add(key, *values)
    return if key.nil? || key.empty?
    @data[key] ||= []
    @data[key] |= values
    save
  end

  def get(key, copy_to_clipboard=false)
    raise "value not found" unless !@data[key].nil?
  
    if !copy_to_clipboard
      @data[key]
    else
      copy_to_clipboard(@data[key].first)
    end
  end

  def copy_to_clipboard(value)
    if Gem.win_platform?
      Open3.pop3('clip') do |stdin, _, _, _|
        stdin.puts value
      end
    else
      if system("which pbcopy > /dev/null 2>&1")
        IO.popen("pbcopy", "w") { |f| f << value }
        puts "'#{value}' copied and ready to paste"
      elsif system("which xclip > /dev/null 2>&1")
        IO.popen("xclip -selection clipboard", "w") { |f| f << value }
        puts "'#{value}' copied and ready to paste"
      else
        puts "no clipboard utility found :/"
        exit 1
      end
    end
  end

  def key_exist?(key)
    @data.key?(key)
  end
  
  def delete(key, *values)
    return delete_key(key) if values.empty?
    delete_values(key, values)
  end

  def keys
    @data.keys
  end

  def dump_data
    JSON.pretty_generate(@data)
  end

  def overview
    @data.transform_values(&:length)
      .map { |key, count| "#{key}: #{count} items" }
      .join("\n")
      .concat("\n")
  end

  def replace(key, *values)
    case values.length
    when 1 then replace_key(key, values.first)
    when 2 then replace_value(key, *values)
    else
      raise ArgumentError, "expected 1 or 2 values, got #{values.length}"
    end
  end

  def search_all(query)
    return [[], []] if query.nil? || query.empty?

    [
      find_matching_keys(query),
      find_matching_values(query),
    ]
  end

  def restore(path)
    @data = load_data(path)
    save
  end

  private

  def delete_key(key)
    @data.delete(key)
    save
  end

  def delete_values(key, values)
    return unless @data.key?(key)
    @data[key] -= values
    save
  end

  def replace_key(old_key, new_key)
    return unless @data.key?(old_key)
    @data[new_key] = @data.delete(old_key)
    save
  end

  def replace_value(key, old_value, new_value)
    return unless @data.key?(key)
    @data[key].map! { |v| v == old_value ? new_value : v }
    save
  end

  def find_matching_keys(query)
    @data.keys.select { |k| k.include?(query) }
  end

  def find_matching_values(query)
    @data.flat_map do |k, values|
      values.select { |v| v.include?(query) }
        .map { |v| [k, v]}
    end
  end
end

class KV
  DEFAULT_PATH = '.kv'.freeze
  COMMANDS = %w[get set add delete keys dump backup replace find help h].freeze

  def initialize(options)
    @path = File.join(ENV['HOME'], options[:path] || DEFAULT_PATH)
    FileUtils.mkdir_p(@path) unless Dir.exist?(@path)
    @db = FileDB.new(@path)
    @copy = options[:copy]
  rescue StandardError => e
    warn "error initializing db: #{e.message}"
    exit 1
  end

  def command(cmd, key='', *values)
    return add(key, *values) if cmd == 'add'
    return delete(key, *values) if cmd == 'delete'
    return keys if cmd == 'keys'
    return dump if cmd == 'dump'
    return backup(key) if cmd == 'backup'
    return replace(key, *values) if cmd == 'replace'
    return find(key) if cmd == 'find'
    return help if cmd == 'help' || cmd == 'h'
    return undo if cmd == 'undo'
    return restore(key) if cmd == 'restore'
      
    if key.empty?
      get(cmd, @copy)
    else
      set(cmd, [key, *values])
    end
  end
  
  def get(key, copy_to_clipboard=false)
    value = @db.get(key, copy_to_clipboard)
    puts value if !copy_to_clipboard
  rescue StandardError => e
    warn "error: #{e.message}"
    exit 1
  end

  def set(key, *value)
    validate_key!(key)
    @db.set(key, *value)
  end
  
  def add(key, *value)
    validate_key!(key)
    @db.add(key, *value)
  end
  
  def delete(key, *value)
    validate_key!(key)
    @db.delete(key, *value)
  end
  
  def keys
    puts @db.keys
  end

  def key_exist?(key)
    validate_key!(key)
    @db.key_exist?(key)
  end

  def dump
    puts @db.dump_data
  end

  def backup(path)
    validate_path!(path)
    File.write(path, @db.dump_data)
  rescue StandardError => e
    warn "error backing up: #{e.message}"
  end

  def overview
    puts @db.overview
  end 

  def replace(key, *value)
    validate_key!(key)
    @db.replace(key, *value)
  rescue ArgumentError => e
    warn e.message
    exit 1
  end

  def find(query)
    key_results, value_results = @db.search_all(query)
    puts "key results:              #{key_results}\n"
    puts "value results ([k, v]):   #{value_results}"
  end

  def restore(path)
    validate_path!(path)
    @db.restore(path)
  rescue StandardError => e
    warn "error restoring from backup: #{e.message}"
  end

  def help
    puts <<~HELP
    usage:
      kv                           list all keys with item count
      kv <key>                     gets values for a key
      kv <key> <value...>          sets value(s) for a key
      kv add <key> <value...>      append value(s) to a key
      kv delete <key> [value...]   delete key or specific values
      kv keys                      list all keys
      kv dump                      dump the database to stdout
      kv backup                    backup database to a new file
      kv restore <path>            restore database from a backup
      kv replace <key> <new_key>   rename a key
      kv replace <key> <old> <new> replace value in a given key  
      kv find <query>              search keys and values
      kv help                      show this help
    HELP
  end
end

def validate_key!(key)
  raise ArgumentError, "key cannot be empty" if key.nil? || key.empty?
end

def validate_path!(path)
  raise ArgumentError, "path cannot be empty" if path.nil? || path.empty?
  raise ArgumentError, "directory doesn't exist" unless File.directory?(File.dirname(path))
end

def parse_options
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: kv <options> [command]"
    opts.on("-pPATH", "--path=PATH", "path to db") { |p| options[:path] = p }
    opts.on("-h", "--help", "show this help") { puts opts; exit }
    opts.on("-c", "--copy", "copy first value to clipboard") { options[:copy] = true }
  end.parse!
  options
end

def main
  options = parse_options
  args = ARGV.map(&:downcase)
  kv = KV.new(options)
  args.empty? ? kv.overview : kv.command(*args)
rescue StandardError => e
  warn "error: #{e.message}"
  exit 1
end

if __FILE__ == $PROGRAM_NAME
  main
end