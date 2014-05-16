#!/usr/bin/env ruby

#require "io/console"
require "ncursesw"

require_relative "lib/feed_window.rb"
require_relative "lib/channel_window.rb"
require_relative "lib/server.rb"

def setup
	Ncurses.initscr
	$screen = Ncurses.stdscr
	Ncurses.cbreak
	Ncurses.noecho
	Ncurses.keypad($screen, true)
	Ncurses.nodelay($screen, true)
end

#Pair 1: Input box, Pair 1+: Windows
def add_colors
	Ncurses.start_color
	colors = %w[RED BLUE GREEN MAGENTA CYAN YELLOW]
	colors.each { |color|
		eval "Ncurses.init_color( Ncurses::COLOR_#{color}, #{rand(0..1000)}, #{rand(0..1000)}, #{rand(0..1000)} )"
	}
	#Ncurses.init_pair( PAIR_NUMBER, BORDER_LINE_COLOR, BORDER_COLOR)
	random_color = eval "Ncurses::COLOR_#{colors.sample}"
	Ncurses.init_pair(2, random_color, Ncurses::COLOR_RED)
	Ncurses.init_pair(3, random_color, Ncurses::COLOR_BLUE)
	Ncurses.init_pair(4, random_color, Ncurses::COLOR_GREEN)
	Ncurses.init_pair(5, random_color, Ncurses::COLOR_MAGENTA)
	Ncurses.init_pair(6, random_color, Ncurses::COLOR_CYAN)
	Ncurses.init_pair(7, random_color, Ncurses::COLOR_YELLOW)
end

def exec(cmd_string)
	cmd, *params = cmd_string.split(" ")
	case cmd
	when "connect"
		hostname = params.first
		@server = Server.new(hostname)
		@channels << ChannelWindow.new($screen, @user_input.window_height, 
																			 hostname, @server.buffer)
		@panes << Ncurses::Panel::new_panel(@channels.last.window)
	when "join"
		channel_name = params.first
		@server.join_channel(channel_name)
		@channels <<	ChannelWindow.new($screen, @user_input.window_height, 
																		channel_name, (@server.channels[channel_name.to_sym].buffer)) 
		@panes << Ncurses::Panel::new_panel(@channels.last.window)
	end
end

begin
	setup()
	add_colors()

	@user_input = FeedWindow.new($screen)

	@channels = []
	@panes = []

	#Ncurses::Panel::update_panels
	#Ncurses.doupdate

	current_chan = *(-1..@channels.length)
	current_chan = current_chan.cycle

	@user_input.reset_cursor
	top = @panes.cycle
	while (keypress = $screen.getch) != Ncurses::KEY_F1 do
		case keypress
		when 9 #Is a Tab
			current_chan.next
			Ncurses::Panel::top_panel(top.next)
		when (32..255) #Any regular character
			@user_input.read_key(keypress)
		when Ncurses::KEY_BACKSPACE, "\b".ord
			@user_input.read_key(keypress)
		############################################
		when Ncurses::KEY_F2
			this_chan = @channels[current_chan.peek].name
			@channels[0].window.mvaddstr(5, 5, @server.channels[this_chan.to_sym].buffer.length.to_s)
		when Ncurses::KEY_ENTER, "\n".ord
			if @user_input.buffer[0] == "/"
				cmd_string = (@user_input.buffer[1..-1])
				exec(cmd_string)
			else
				this_chan = @channels[current_chan.peek].name
				@server.chan_message(this_chan, @user_input.buffer)
				@server.channels[this_chan.to_sym].buffer << @user_input.buffer
			end
			@user_input.clear_buffer
		end

		@channels.each { |channel|
			channel.check_for_updates
		}
		
		###Refresh###
		Ncurses::Panel::update_panels()
		@user_input.window.noutrefresh
		@user_input.draw_border
		Ncurses.doupdate
	end

ensure
	Ncurses.endwin
end

