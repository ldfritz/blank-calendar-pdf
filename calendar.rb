#!/usr/bin/env ruby

require "optparse"
require "date"
require "prawn"
require "prawn/measurement_extensions"

### About Script
VERSION = "0.1.0"
APPNAME = "calendar.rb"
### END About Script

### Calendar Logic
class Calendar

  FONT = "/usr/share/fonts/truetype/ttf-dejavu/DejaVuSansMono.ttf"
  DATE_FG    = "d9d9d9"
  HEADING_FG = "000000"
  OTHER_BG   = "f0f0f0"

  def initialize(year, month)
    @year  = year
    @month = month
  end

  def first_of_month
    @first_date ||= Date.new(@year, @month)
  end

  def last_of_month
    last_of_month ||= if @month == 12
      # The day before the first of next year.
      Date.new(@year + 1, 1         ) - 1
    else
      # The day before the first of next month.
      Date.new(@year    , @month + 1) - 1
    end
  end

  def number_of_weeks
    ((last_of_month.mday + first_of_month.wday - 1) / 7) + 1
  end

  def render_file(filename, page_size)
    doc = Prawn::Document.new(:page_size => page_size,
                              :page_layout => :landscape)

    ### Config
    cell_width  = doc.bounds.right / 7
    cell_height = (doc.bounds.top - 1.in) / number_of_weeks
    font_size   = (cell_height < cell_width ? cell_height : cell_width) * 0.8
    doc.font FONT
    ### END Config

    ### Title
    doc.bounding_box([0, doc.bounds.top],
                     :width => doc.bounds.right,
                     :height => 1.in) do
      doc.text(first_of_month.strftime("%B %Y"),
               :size => 0.75.in,
               :color => HEADING_FG)
    end
    ### END Title

    ### Weekday Labels
    %w[Sun Mon Tue Wed Thu Fri Sat].each_with_index do |label, i|
      doc.bounding_box([(cell_width * i),
                        (doc.bounds.top - 0.75.in)],
                       :width => cell_width) do
        doc.text(label,
                 :size => 0.25.in,
                 :color => HEADING_FG)
      end
    end
    ### END Weekday Labels

    ### Dates
      (0...last_of_month.mday).each do |d|
      date = first_of_month + d
      x_coord = cell_width * date.wday
      y_coord = doc.bounds.top - 1.in - (cell_height * ((date.mday + first_of_month.wday - 1) / 7))
      doc.bounding_box([x_coord, y_coord],
                       :width => cell_width,
                       :height => cell_height) do

        doc.stroke_bounds
        doc.move_down 5
        doc.text(date.mday.to_s,
                 :size  => font_size,
                 :align => :right,
                 :color => DATE_FG)
      end
      end
    ### END Dates

    ### Leading Dates
    ### END Leading Dates
    
    ### Trailing Dates
    ### END Trailing Dates

    doc.render_file(filename)
  end
end

### Option Parsing
options = {}
optparser = OptionParser.new do |opts|
  opts.banner = "usage: #{APPNAME} [OPTIONS] YEAR MONTH [LETTER|LEGAL|TABLOID]"
  opts.separator ""
  opts.separator "Options:"

  opts.on("-h", "--help", "Show this message and exit.") do
    options[:show_help] = true
  end

  opts.on("--test", "Run tests and exit.") do
    options[:run_tests] = true
  end

  opts.on("-V", "--version", "Print version and exit.") do
    puts "#{APPNAME} #{VERSION}"
    exit
  end
end
optparser.parse!
### END Option Parsing

### Tests
if options[:run_tests]
  require "minitest/autorun"
  class CalendarTests < Minitest::Test
    def test_first_of_month
      assert(Calendar.new(2014, 11).first_of_month == Date.new(2014, 11, 1))
    end

    def test_last_of_month
      assert(Calendar.new(2014, 11).last_of_month  == Date.new(2014, 11, 30))
    end
  end
  exit
end
### END Tests

### ARGV Parsing
  ### Date
options[:year]  = ARGV[0].to_i
options[:month] = ARGV[1].to_i
unless options[:year] > -1 and options[:month] >= 1 and options[:month] <= 12
  options[:show_help] = true
end

  ### Size
options[:page_size] = ARGV[2] && ARGV[2].upcase || "LETTER"
unless %w[LETTER LEGAL TABLOID].include?(options[:page_size])
  options[:show_help] = true
end

  ### Destination Filename
options[:filename] = "%d-%02d-%s.pdf" % [options[:year],
                                        options[:month],
                                        options[:page_size]]
### END ARGV Parsing

### Help Output
if options[:show_help]
  puts optparser
  exit
end
### Help Output

### Execution
calendar = Calendar.new(options[:year], options[:month])
calendar.render_file(options[:filename], options[:page_size])
### END Execution
