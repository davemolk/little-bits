#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'
require 'securerandom'
require File.expand_path('io_utils.rb', File.dirname(__FILE__))
require File.expand_path('http_utils.rb', File.dirname(__FILE__))

class PW
  DEFAULT_DIR = ".pw"
  WORDLISTS = {
    "large": "https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt",
    "short1": "https://www.eff.org/files/2016/09/08/eff_short_wordlist_1.txt",
    "short2": "https://www.eff.org/files/2016/09/08/eff_short_wordlist_2_0.txt",
  }

  def initialize
    @path = File.join(ENV['HOME'], DEFAULT_DIR)
    FileUtils.mkdir_p(@path) unless Dir.exist?(@path)
  end

  def get_data
    WORDLISTS.each do |k, v|
      data = HttpUtils.fetch_data(v)
      data.gsub!(/[\d\t]*/, "")
      list_path = File.join(@path, "#{k}.txt")
      File.write(list_path, data)
    end
  end
end

def generate(file, word_count, separator, num=false, special=false, capital=false, complex=false)
  words = File.readlines(file).map(&:chomp)
  special_characters = '!@#$%^&*()_+-=[]{}|;:,.<>?/~'.chars
  capitals = 'ABCDEFGHIJLKMNOPQRSTUVWXYZ'.chars
  
  chosen_words = Array.new(word_count) { words.sample(random: SecureRandom) }
  extras = []

  add_extras = ->(array, condition, extra_pool) do
    if !condition
      return array
    end
    if !complex
      extras << extra_pool.sample
      array
    else
      array.map { |word| "#{word}#{extra_pool.sample}" }
    end
  end
  
  chosen_words = add_extras.call(chosen_words, num, (0..9).to_a)
  chosen_words = add_extras.call(chosen_words, special, special_characters)
  chosen_words = add_extras.call(chosen_words, capital, capitals)

  pw = chosen_words.join(separator)
  pw << extras.join

  IoUtils.copy_to_clipboard(pw, true)
end

def parse_options
  options = {
    separator: "-",
    word_count: 6,
    word_list: "short1.txt",
  }
  OptionParser.new do |opts|
    opts.banner = "usage: pw [option]"
    opts.on("-h", "--help", "show this help") { puts opts }
    opts.on("-w", "--words WORDS", Integer, "number of words to include") { |c| options[:word_count] = c }
    opts.on("-b", "--between", "word separator (default '-')")
    opts.on("-l", "--large", "use EFF large wordlist") { options[:word_list] = "large.txt" }
    opts.on("-s", "--short2", "use EFF short wordlist 2 (default is short wordlist 1)") { options[:word_list] = "short2.txt" }
    opts.on("--initialize", "get the EFF lists and get passwording!") { options[:initialize] = true }
    opts.on("--capital", "include capital letters") { options[:capital] = true }
    opts.on("--numbers", "include numbers") { options[:num] = true }
    opts.on("--special", "include special chars") { options[:special] = true }
    opts.on("--complex", "include number/special char/capital at the end of each word (dependong on which is selected)") { options[:complex] = true }
    opts.on("--custom CUSTOM", "path to custom wordlist") { |c| options[:custom] = c }
  end.parse!
  options
end

def init
  initializer = PW.new()
  initializer.get_data()
end

def main
  options = parse_options
  init unless !options[:initialize]
  path = options[:custom] ? options[:custom] : File.join(ENV['HOME'], ".pw", options[:word_list])
  generate(path, options[:word_count], options[:separator], options[:num], options[:special], options[:capital], options[:complex])
rescue StandardError => e
  warn "error: #{e.message}"
  exit 1
end

if __FILE__ == $PROGRAM_NAME
  main
end