#!/usr/bin/env ruby
#
require 'ncursesw'

class Reel
  attr_accessor :window
  def initialize(server)
    @window = Ncurses::WINDOW.new(Ncurses.LINES-feed_height, 0, 0, 0)
  end
end

