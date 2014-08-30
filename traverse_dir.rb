#!/usr/bin/ruby
# encoding: utf-8

require 'uri'

class MyDirectory 
	include Comparable
	def initialize(name, fullpath)
		@name = name
		@fullpath = fullpath
		@mediafiles = Array.new
		@subdirs = Array.new
		traverse
	end
	attr_reader :name, :fullpath, :mediafiles, :subdirs 
	
	def <=>(otherDir)
		return self.name <=> otherDir.name
	end

	def traverse
		Dir.foreach(fullpath) { |f|
			path = File.join(@fullpath, f)
			begin
				if f == "." || f == ".."
                        		next
				elsif File.directory?(path)
					@subdirs.push(MyDirectory.new(f, path))
				elsif f =~  /\.mkv$/ || f =~  /\.mp4$/
					@mediafiles.push(f)
				end	
			rescue
				# puts "Malformed file name: #{f}"
			end
		}		
	end

	def has_media_children? 
		return true if @mediafiles.size > 0
		@subdirs.each { |d|
			return true if d.has_media_children?
		}
		return false
	end

	def recursive_print(depth)
		if has_media_children?
			puts @fullpath
			@mediafiles.sort.each { |f|
				puts "    #{f}"
			}
			@subdirs.sort.each { |d|
				d.recursive_print(depth+1) 
			}
		end
	end

	def print_html(baseurl)
		if has_media_children?
			puts "<div class=\"dirlisting\"><p>#{@name.gsub("_", " ")}</p>"
			puts "<ul>" if @mediafiles.size > 0
                        @mediafiles.sort.each { |f|
				niceuri = URI.escape(baseurl + "/" + f)
                                puts "<li><a href=\"#{niceuri}\" class=\"medialink\">#{f.gsub("_", " ")}</a></li>"
                        }
			puts "</ul>" if @mediafiles.size > 0
                        @subdirs.sort.each { |d|
                                d.print_html(baseurl + "/" + d.name) 
                        }
			puts "</div>" 
                end
	end	
end

if ARGV.size < 2
	$stderr.puts "This script takes two parameters:"
	$stderr.puts "  1. base directory, the directory where the traversal starts"
        $stderr.puts "  2. the URL matching this path"
 	$stderr.puts "Output is written to STDOUT!"
	$stderr.puts "Example:"
	$stderr.puts "ruby traverse_dir.rb /var/www/html http://12.34.56.78/ > /var/www/html/video.html" 
	exit 1
end

basedir = ARGV[0]
baseurl = ARGV[1]

x = MyDirectory.new("", basedir) 

puts "<!DOCTYPE html>"
puts "<html>"
puts "<head>"
puts "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />"
puts "<title>RollerCaster</title>"
puts "<link rel=\"stylesheet\" type=\"text/css\" href=\"CastVideos.css\">"
puts "<script type=\"text/javascript\" src=\"https://www.gstatic.com/cv/js/sender/v1/cast_sender.js\"></script>"
puts "<script type=\"text/javascript\" src=\"CastVideos.js\"></script>"
puts "</head><body>"
puts "<div id=\"toggleplayer\">Toggle player</div>"
puts "<div id=\"upperbar\"><span id=\"rollercaster\">RollerCaster</span> · "
puts "         <span id=\"upperinfo\">nothing</span> <span id=\"onchromecast\">(on Chromecast)</span><span id=\"locally\">(locally)</span>"
puts "</div>"
puts "<div id=\"erroroverlay\"><div id=\"errorbox\"><h2>Could not initialize RollerCaster</h2><p>RollerCaster could not be initialized. This means that either you are not using Chrome or Chromium or the Chromecast add on is missing.</p></h2></div></div>"
puts "<div id=\"infooverlay\"><div id=\"infobox\"><h2>About RollerCaster</h2><p>RollerCaster started as a proof of concept by Mattias Schlenker that it is easily possible to stream media from a local NAS to your Chromecast. Get the code and the documentation at <a href=\"https://github.com/mschlenker/RollerCaster\" target=\"blank\">github.com/mschlenker/RollerCaster</a>. Contact me by Email or send my a beer via PayPal: <a href=\"mailto:ms@mattiasschlenker.de\">ms@mattiasschlenker.de</a>.</p><p>If you are a vendor of NAS devices you might contact me to buy a few hours of consulting to include RollerCaster to your devices.</p><div id=\"infoclose\">[close]</div></div></div>"
puts "<div id=\"main_video\">"
puts "        <div class=\"imageSub\">"
puts "           <div class=\"blackbg\" id=\"playerstatebg\">IDLE</div>"
puts "           <div class=\"label\" id=\"playerstate\">IDLE</div>"
puts "           <img src=\"images/bunny.jpg\" id=\"video_image\">"
puts "           <div id=\"video_image_overlay\"></div>"
puts "           <video id=\"video_element\">"
puts "           </video>"
puts "        </div>"
puts "        <div id=\"media_control\">"
puts "           <div id=\"play\"></div>"
puts "           <div id=\"pause\"></div>"
puts "           <div id=\"progress_bg\"></div>"
puts "           <div id=\"progress\"></div>"
puts "           <div id=\"progress_indicator\"></div>"
puts "           <div id=\"fullscreen_expand\"></div>"
puts "           <div id=\"fullscreen_collapse\"></div>"
puts "           <div id=\"casticonactive\"></div>"
puts "           <div id=\"casticonidle\"></div>"
puts "           <div id=\"audio_bg\"></div>"
puts "           <div id=\"audio_bg_track\"></div>"
puts "           <div id=\"audio_indicator\"></div>"
puts "           <div id=\"audio_bg_level\"></div>"
puts "           <div id=\"audio_on\"></div>"
puts "           <div id=\"audio_off\"></div>"
puts "           <div id=\"duration\">00:00:00</div>"
puts "        </div>"
puts "      </div>"
puts "<div id=\"medialist\">"
x.print_html(baseurl) 
puts "</div>"
puts "<script type=\"text/javascript\">"
puts "  var CastPlayer = new CastPlayer();"
puts "</script>"
puts "</body></html>"
