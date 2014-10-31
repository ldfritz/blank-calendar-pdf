#!/usr/bin/env ruby

require "optparse"
require "date"
require "prawn"

### About Script
VERSION = "0.1.0"
APPNAME = "calendar.rb"
### END About Script

### Calendar Logic
class Calendar
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
end
### END Calendar Logic

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
options[:year]  = ARGV[0].to_i
options[:month] = ARGV[1].to_i
unless options[:year] > -1 and options[:month] >= 1 and options[:month] <= 12
  options[:show_help] = true
end

options[:page_size] = ARGV[2] && ARGV[2].upcase || "LETTER"
unless %w[LETTER LEGAL TABLOID].include?(options[:page_size])
  options[:show_help] = true
end
### END ARGV Parsing

### Help Output
if options[:show_help]
  puts optparser
  exit
end
### Help Output

### for calendar class
first_of_month  = Date.new(options[:year], options[:month])

last_of_month   = if options[:month] == 12
  Date.new(options[:year] + 1, 1) - 1
else
  Date.new(options[:year], options[:month] + 1) - 1
end

weeks_in_month = ((last_of_month.mday + first_of_month.wday - 1) / 7) + 1
### END for calendar class

### Color Magic Numbers
color_of_date = "d9d9d9"
color_of_weekday_name = "000000" 
color_of_other_month_background = "f0f0f0"
### END Colors Magic Numbers


pdf = Prawn::Document.new(:page_size => options[:page_size],
                          :page_layout => :landscape)

pdf.define_grid(:columns => 7, :rows => weeks_in_month + 1, :gutter => 0)
pdf.font("/usr/share/fonts/truetype/ttf-dejavu/DejaVuSansMono.ttf")

box_height = 0
pdf.grid(1, 1).bounding_box do
  box_height = pdf.bounds.top
end

pdf.font_size(box_height * 0.75)

pdf.grid([0, 0], [0, 6]).bounding_box do
  pdf.text first_of_month.strftime("%B %Y")
end

date = first_of_month
if date.wday > 0
  date -= date.wday
end

until date > last_of_month and date.wday == 0
  col = date.wday
  row ||= 0
  if date.month == options[:month]
    row = (date.mday + first_of_month.wday - 1) / 7
  end

  pdf.grid(row + 1, col).bounding_box do
    if row == 0
      pdf.float do
        pdf.move_up 20
        pdf.font_size(20) { pdf.text date.strftime("%a"), :align => :right, :color => color_of_weekday_name }
      end
    end

    if date.month != options[:month]
      pdf.fill_color color_of_other_month_background 
      pdf.fill_rectangle [0, pdf.bounds.top], pdf.bounds.right, pdf.bounds.top
    end

    pdf.stroke_bounds

    pdf.move_down 5
    pdf.text date.mday.to_s, :align => :right, :color => color_of_date
  end

  date += 1
end

pdf.render_file(first_of_month.strftime("%Y-%m-#{options[:page_size].downcase}.pdf"))
