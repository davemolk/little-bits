#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'
require 'securerandom'
require './io_utils.rb'
require './http_utils.rb'

class PW
  DEFAULT_DIR = ".pw"
  LARGE_WORDLIST = "https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt"
  SHORT_WORDLIST = "https://www.eff.org/files/2016/09/08/eff_short_wordlist_1.txt"
  SHORT_WORDLIST2 = "https://www.eff.org/files/2016/09/08/eff_short_wordlist_2_0.txt"

  def initialize
    @path = File.join(ENV['HOME'], DEFAULT_DIR)
    FileUtils.mkdir_p(@path) unless Dir.exist?(@path)

    # download files
    # clean files (and save)
    # profit
  end

  def get_data(url)
    
  end

  def clean_data
    Dir.chdir(@path)
    files = Dir.glob("*.txt")
    files.each do |f|
      # not doing dice rolls, so change 11111	abacus to abacus
      data = File.readlines(f).map{ |line| line.sub(/^[\d]*[\t\s]*/, "") }
      cleaned = data.join("")
      File.write(f, cleaned)
    end
  end
end

def generate(file, word_count, separator)
  words = File.readlines(file).map(&:chomp)
  chosen_words = []
  begin
    word_count.times { chosen_words << words.sample }
  rescue
    word_count.times { chosen_words << words.sample(random: SecureRandom) }
  end
  pw = chosen_words.join(separator)
  IoUtils.copy_to_clipboard(pw)
  puts pw
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
  end.parse!
  options
end

def main
  options = parse_options
  path = File.join(ENV['HOME'], ".pw", options[:word_list])
  generate(path, options[:word_count], options[:separator])
rescue StandardError => e
  warn "error: #{e.message}"
  exit 1
end

if __FILE__ == $PROGRAM_NAME
  main
end