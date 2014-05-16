#!/bin/bash/env ruby

require 'ncursesw'

class FeedWindow
	attr_accessor :window, :window_height, :buffer, :server
	def initialize(screen)
	  @window_height = 3
	  @window = Ncurses::WINDOW.new(@window_height, 0, Ncurses.LINES-@window_height, 0)
	  @buffer ||= ""
	  post_init
	end

	def post_init
	  colorize()
	  draw_border()
	end

	def colorize
	  Ncurses.init_pair(1, Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK)
	  @window.color_set(1, nil)
	end

	def draw_border
	  @window.border(0, 0, 0, 0, 0, 0, 0, 0)
	end

	def reset_cursor
	  @window.move(1, 1)
	end

	def clear_buffer
	  @buffer = ""
	  @window.mvaddstr(1, 1, (" "*(@window.getmaxx-2)) )
	  reset_cursor
	end

	def read_key(char)
	  case char
	  when 32..255
	    @window.move( 1, (@buffer.length+1) )
	    @buffer << char
	    @window.mvaddstr( 1,(@buffer.length+1), @buffer[-1] )
	  when Ncurses::KEY_BACKSPACE, "\b".ord
	    @window.mvaddstr( 1,(@buffer.length+1), " " )
	    @buffer.chop!
	    @window.move( 1, (@buffer.length+2) )
	  end
	end

end

