require "prawn"
require "date"
#require "letters"

VERSION  = "0.1.0"
APP_NAME = __FILE__

### Command Line Interface

  ### Messages
USAGE = "usage: #{APP_NAME} YEAR MONTH [LETTER|LEGAL|TABLOID]"
  ### END Messages

if ARGV[1]
  year  = ARGV[0].to_i
  month = ARGV[1].to_i
else
  puts USAGE
  exit
end

page_size = if ARGV[2]
  size = ARGV[2].upcase
  if %w[LETTER LEGAL TABLOID].include?(size)
    size
  else
    puts USAGE
    exit
  end
else
  "LETTER"
end
### END Command Line Interface

first_of_month  = Date.new(year, month)

last_of_month   = if month == 12
  Date.new(year + 1, 1) - 1
else
  Date.new(year, month + 1) - 1
end

weeks_in_month = ((last_of_month.mday + first_of_month.wday - 1) / 7) + 1

### Color Magic Numbers
color_of_date = "d9d9d9"
color_of_weekday_name = "000000" 
color_of_other_month_background = "f0f0f0"
### END Colors Magic Numbers

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

### Testing
RUN_TEST = false
if RUN_TEST
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
### END Testing

pdf = Prawn::Document.new(:page_size => page_size,
                          :page_layout => :landscape)

pdf.define_grid(:columns => 7, :rows => weeks_in_month + 1, :gutter => 0)
pdf.font("/usr/share/fonts/truetype/ttf-dejavu/DejaVuSansMono.ttf")

box_height = 0
pdf.grid(1, 1).bounding_box do
  box_height = pdf.bounds.top
#  puts "%7s %7.2fx%7.2f" % [page_size, pdf.bounds.top, pdf.bounds.right]
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
  if date.month == month
    row = (date.mday + first_of_month.wday - 1) / 7
  end

  pdf.grid(row + 1, col).bounding_box do
    if row == 0
      pdf.float do
        pdf.move_up 20
        pdf.font_size(20) { pdf.text date.strftime("%a"), :align => :right, :color => color_of_weekday_name }
      end
    end

    if date.month != month
      pdf.fill_color color_of_other_month_background 
      pdf.fill_rectangle [0, pdf.bounds.top], pdf.bounds.right, pdf.bounds.top
    end

    pdf.stroke_bounds

    pdf.move_down 5
    pdf.text date.mday.to_s, :align => :right, :color => color_of_date
  end

  date += 1
end

pdf.render_file(first_of_month.strftime("%Y-%m-#{page_size.downcase}.pdf"))
