# Blank Calendar PDF

Generate a PDF calendar for a given month.

Since this is the calendar I like to hang on my fridge and read from across the room, it takes up the whole page and has ridiculously large numbers.

Examples of the output can be seen in [examples/](https://github.com/ldfritz/blank-calendar-pdf/blob/master/examples/).

## How to Use

* Clone the repo.
* Install the required gems. `bundle install`
* Run `calendar.rb`, providing the year, month, and optionally the paper size.
  * `./calendar.rb 2015 09` generates [2015-09-letter.pdf](https://github.com/ldfritz/blank-calendar-pdf/blob/master/examples/2015-09-letter.pdf).
  * `./calendar.rb 2015 10 tabloid` generates [2015-10-tabloid.pdf](https://github.com/ldfritz/blank-calendar-pdf/blob/master/examples/2015-10-tabloid.pdf).

## Dependencies

* Prawn
