#!/usr/bin/env ruby

require "reel.rb"
#
class Feed
  attr_accessor :buffer, :current_reel
  def initialize(server)
    @server = server
    @window = Ncurses::WINDOW.new(4, 0, Ncurses.LINES-4, 0)
    @server_window = Ncurses::WINDOW.new()
    @buffer = ""
  end

  def read(char)
    case char
      when 32..255 #Regular characters
        @buffer << char.chr
      when 8 #Backspace key
        @buffer.chop!
      when 10 #Enter key
        parse(@buffer)
    end
  end

  #Send "/" entries to correct spot
  def parse(buff)
    if buff[0] == "/"
      cmd, *params = buff.delete("/").split(" ")
      dispatch(cmd, params)
    else
      #
    end
  end

  def dispatch(command, params)
    case command
    when "connect"
    when "join"
      server.join_channel(params)
    when "msg"
      user, *message = params
      #Convert message arr back into string
      message = message.join(" ")
      server.priv_message(user, message)
    when "quit"
      server.quit
    end
  end

  def add_channel
    
  end
end

