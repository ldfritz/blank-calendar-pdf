#!/usr/bin/env ruby

require "optparse"
require "date"
require "prawn"
require "prawn/measurement_extensions"

### About Script
VERSION = "0.2.0"
APPNAME = File.basename(__FILE__)
### END About Script

### Calendar Logic

# Public: Methods that calculate the dates to be printed and create the
# calendar PDF using Prawn.
class Calendar

  # Public: Font used on the calendar.
  FONT  = "/usr/share/fonts/truetype/ttf-dejavu/DejaVuSansMono.ttf"
  # Public: Color of black text.
  BLACK = "000000"
  # Public: Color of gray text.
  GRAY  = "d9d9d9"
  # Public: Color of white text.
  WHITE = "ffffff"

  # Public: Initialize a Calendar.
  #
  # year      - An Integer of the year.
  # month     - An Integer of the year.
  # page_size - A String of the page size (LETTER, LEGAL, or TABLOID).
  def initialize(year, month, page_size)
    @year  = year
    @month = month
    @doc   = Prawn::Document.new(:page_size => page_size,
                                 :page_layout => :landscape)
    @doc.font FONT
  end

  # Public: Given a Date return its bounding box coordinates.
  #
  # date - A Date to be positioned.
  #
  # Returns an Array of Floats telling the x and y coordinates for
  # the bounding box, in pixels.
  def cell_coords(date)
    x = cell_width * date.wday
    y = (@doc.bounds.top - 1.in) - (cell_height * cell_row(date))
    [x, y]
  end

  # Public: Calculate the height for the date bounding boxes.
  #
  # Returns a Float of the height of the date bounding boxes in pixels.
  def cell_height
    @cell_height ||= (@doc.bounds.top - 1.in) / number_of_weeks
  end

  # Public: Figure out which week of the month a date is.
  #
  # date - A Date that would be printed on this calendar.
  #
  # Returns an Integer of which week a date is.
  def cell_row(date)
    if    date < first_of_month
      cell_row(first_of_month)
    elsif date > last_of_month
      cell_row(last_of_month)
    else
      (date.mday + first_of_month.wday - 1) / 7
    end
  end

  # Public: Calculate the width for the date bounding boxes.
  #
  # Returns a Float of the width of the date bounding boxes in pixels.
  def cell_width
    @cell_width ||= @doc.bounds.right / 7
  end

  # Public: Return the date for the first of the month.
  #
  # Returns a Date of the first of the month.
  def first_of_month
    @first_of_month ||= Date.new(@year, @month)
  end

  # Public: Figure out the largest font size that can be used for the
  # date text.
  #
  # Returns a Float of the size of the font for the calendar dates.
  def font_size
    @font_size ||= [cell_height, cell_width].sort.shift * 0.8
  end

  # Public: Return the date for the last of the month.
  #
  # Returns a Date of the last of the month.
  def last_of_month
    # See if the month is December
    @last_of_month ||= if @month == 12
      # If so, return the day before the first of next year.
      Date.new(@year + 1, 1         ) - 1
    else
      # If not, return the day before the first of next month.
      Date.new(@year    , @month + 1) - 1
    end
  end

  # Public: Return how many weeks are in the month.  The week starts on
  # Sunday.
  #
  # Returns an Integer of how many weeks are in this month.
  def number_of_weeks
    @number_of_weeks ||= cell_row(last_of_month) + 1
  end

  # Public: Make a PDF calendar.
  #
  # filename - A String of the filename of where to write the calendar.
  #
  # Returns True if successful.
  def render_file(filename)
    ### Title
    @doc.bounding_box([0, @doc.bounds.top],
                      :width => @doc.bounds.right,
                      :height => 1.in) do
      @doc.text(first_of_month.strftime("%B %Y"),
                :size => 0.75.in,
                :color => BLACK)
    end
    ### END Title

    ### Weekday Labels
    %w[Sun Mon Tue Wed Thu Fri Sat].each_with_index do |label, i|
      @doc.bounding_box([cell_width * i,
                        @doc.bounds.top - 0.75.in],
                        :width => cell_width) do
        @doc.text(label,
                  :size => 0.25.in,
                  :color => BLACK)
      end
    end
    ### END Weekday Labels

    ### Dates
      (0...last_of_month.mday).each do |d|
        date = first_of_month + d
        @doc.bounding_box(cell_coords(date),
                          :width => cell_width,
                          :height => cell_height) do
          @doc.stroke_bounds
          @doc.move_down 5
          @doc.text(date.mday.to_s,
                   :size  => font_size,
                   :align => :right,
                   :color => GRAY)
        end
      end
    ### END Dates

    ### Leading Dates
    ((first_of_month.wday * -1)...0).each do |d|
      date = first_of_month + d
      @doc.bounding_box(cell_coords(date),
                        :width => cell_width,
                        :height => cell_height) do
        @doc.fill_color GRAY
        @doc.fill_rectangle([0, @doc.bounds.top], @doc.bounds.right, @doc.bounds.top)
        @doc.stroke_bounds
        @doc.move_down 5
        @doc.text(date.mday.to_s,
                 :size  => font_size,
                 :align => :right,
                 :color => WHITE)
      end
    end
    ### END Leading Dates
    
    ### Trailing Dates
    #!! DUPLICATION
    (1..(6 - last_of_month.wday)).each do |d|
      date = last_of_month + d
      @doc.bounding_box(cell_coords(date),
                        :width => cell_width,
                        :height => cell_height) do
        @doc.fill_color GRAY
        @doc.fill_rectangle([0, @doc.bounds.top], @doc.bounds.right, @doc.bounds.top)
        @doc.stroke_bounds
        @doc.move_down 5
        @doc.text(date.mday.to_s,
                 :size  => font_size,
                 :align => :right,
                 :color => WHITE)
      end
    end
    ### END Trailing Dates

    ### Version
    @doc.canvas do
      @doc.fill_color BLACK
      @doc.font_size(6) do
        @doc.draw_text("v%s" % VERSION, :at => [@doc.bounds.right - 59, 30])
      end
    end
    ### END Version

    @doc.render_file(filename)
    true
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

  opts.on("--version", "Print version and exit.") do
    puts "#{APPNAME} #{VERSION}"
    exit
  end
end
optparser.parse!
### END Option Parsing

### Tests
if options[:run_tests]
  require "minitest/autorun"
  class CalendarTests < Minitest::Test # :nodoc: all
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
                                         options[:page_size].downcase]
### END ARGV Parsing

### Help Output
if options[:show_help]
  puts optparser
  exit
end
### END Help Output

### Execution
calendar = Calendar.new(options[:year],
                        options[:month],
                        options[:page_size])
calendar.render_file(options[:filename])
### END Execution
