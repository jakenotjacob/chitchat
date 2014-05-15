#!/usr/bin/env ruby
#
require 'ncursesw'

class ChannelWindow
  attr_accessor :window, :name, :buffer, :current_line, :color_pair_number
  def initialize(screen, feed_height, name, buffer)
    @window = Ncurses::WINDOW.new(Ncurses.LINES-feed_height, 0, 0, 0)
    @name = name
    @buffer = buffer
    @current_line = 0
    post_init
  end

  def post_init
    colorize()
    draw_border()
    add_label()
    enable_scroll()
  end

  def colorize
    @color_pair_number = rand(2..6)
  end

  def draw_border
    @window.attron(Ncurses::COLOR_PAIR(@color_pair_number))
    @window.border(0, 0, 0, 0, 0, 0, 0, 0)
    @window.attroff(Ncurses::COLOR_PAIR(@color_pair_number))
    add_label
  end

  def add_label
    @window.mvaddstr(0, (@window.getmaxx/2), @name)
  end

  def enable_scroll
    @window.scrollok(true)
    @window.setscrreg(1, (@window.getmaxy-2) )
  end

  def update
    @window.scrl(1)
    @window.mvaddstr( (@window.getmaxy-2), 1, @buffer[@current_line])
    @current_line += 1
    draw_border
  end

  def check_for_updates
    if @current_line < @buffer.length
      update()
      return true
    else
      return false
    end
  end

end

