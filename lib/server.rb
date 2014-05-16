#!/usr/bin/env ruby
#
require "socket"
require "yaml"
# This class fetches the network IO, acting as the main handler
# that will route messages to the correct Reel (channel window).

class Server
	attr_accessor :stream, :hostname, :buffer,
								:channels, :nick, :user, :name
	def initialize(server, port = 6667)
		@stream = TCPSocket.open(server, port)
		@buffer = []
		@channels = {}
		@nick, @user, @real, @pass = user_config
    get_hostname
		post_initialize
	end
	def post_initialize
		wind
		join_server
	end

	def user_config
		conf = YAML.load_file("lib/config.yaml")
		return conf["nickname"], conf["username"], conf["realname"], conf["nickserv"]
	end

  def get_hostname
    ip = @stream.peeraddr.last
    @hostname = %x(host #{ip}).split(" ").last.chop!
  end

	def join_server
		stream.puts "NICK #{@nick}"
		stream.puts "USER #{@user} #{@user} #{@hostname} :#{@real}"
	end

	def identify
		stream.puts "NickServ identify #{@pass}"
	end

	def wind
		Thread.new { 
			while line = stream.gets.chomp
				route(line)
			end
		}
	end

	def keep_alive
		stream.puts "PONG :#{hostname}"
	end

	def join_channel(chan)
		stream.puts "JOIN ##{chan}"
		@channels[chan.to_sym] = Server::Channel.new(chan)
	end

	#Send incoming strings to correct channel buffer
	def route(str) 
		msg = str.split(" ")

		if ( msg[0] == "PING" )
			keepalive()
		#Routing to server buffer
		elsif ( msg[0].include? "NickServ" )
			identify()
		elsif ( msg[0].include? @hostname )
			@buffer << str
		#Routing to channels
		elsif msg[2][0] == "#"
			channel_name = msg[2].delete("#")
			chan_sym = channel_name.to_sym
			if channels.has_key? chan_sym
				@channels[chan_sym].parse(msg)
			else
				join_channel(channel_name)
			end
		else
			@buffer << "xXx UNKNOWN TEXT xXx ->#{str}<- xXx xXx"
		end
	end

	def priv_message(user, message)
		@stream.puts "PRIVMSG #{user} :#{message}"
	end

	def chan_message(channel, message)
		@stream.puts "PRIVMSG ##{channel} :#{message}"
	end

	def quit
		@stream.puts "QUIT"
	end

	#Start Channel class
	class Channel
		attr_accessor :name, :buffer, :topic
		def initialize(name)
			@name = name
			@buffer = []
		end

		def parse(msg)
			user = get_username(msg[0])
			operation = msg[1]
			#Remove ":" from string
			text = msg[3..-1].join(" ")
			text = text[1..-1]
			write_buffer(operation, user, text)
		end

		def write_buffer(op, user, text) 
			case op
			when "PRIVMSG"
				@buffer << "<#{user}> #{text}"
			when "JOIN"
				@buffer << "\t>> #{user} has joined the channel. <<"
			when "PART"
				@buffer << "\t>> #{user} has left the channel. <<"
			when "QUIT"
				@buffer << "\t>> #{user} has quit the server. <<"
			when "TOPIC"
				@buffer << "\t>> Topic changed to: #{text} <<"
			end
		end

		#Discard the user's hostname... for now.
		def get_username(str)
			username = str.split("!").first
			username = username.delete(":")
		end
	end
	##End Channel Class

end

