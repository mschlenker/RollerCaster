#!/usr/bin/ruby
# encoding: utf-8

require 'uri'
require 'rexml/document' 

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

	def print_xml(baseurl, parent)
		if has_media_children?
			dirname = parent.add_element("div")
			dirname.attributes["class"] = "dirlisting"
			dirp = dirname.add_element("p")
			dirp.text = @name.gsub("_", " ")
			if @mediafiles.size > 0
				list = dirname.add_element("ul")
				@mediafiles.sort.each { |f|
					niceuri = URI.escape(baseurl + "/" + f)
					li = list.add_element("li") 
					a = li.add_element("a")
					a.attributes["href"] = f.gsub("_", " ")
					a.attributes["class"] = "medialink" 
				}
			end
			@subdirs.sort.each { |d|
				d.print_xml(baseurl + "/" + d.name, dirname) 
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

doc = REXML::Document.new('<!DOCTYPE html><html></html>')
head = doc.root.add_element("head")
body = doc.root.add_element("body")
title = head.add_element("title")
title.text = "RollerCaster"
meta = head.add_element("meta")
meta.attributes["http-equiv"] = "Content-Type"
meta.attributes["content"] = "text/html; charset=UTF-8"
link = head.add_element("link")
link.attributes["rel"] = "stylesheet"
link.attributes["type"] = "text/css"
link.attributes["href"] = "CastVideos.css"
script = head.add_element("script")
script.attributes["type"]  = "text/javascript"
script.attributes["src"]  = "https://www.gstatic.com/cv/js/sender/v1/cast_sender.js"
script.text = " "
script = head.add_element("script")
script.attributes["type"]  = "text/javascript"
script.attributes["src"]  = "CastVideos.js"
script.text = " "
togglep = body.add_element("div")
togglep.attributes["id"] = "toggleplayer"
togglep.text = "Toggle player"
upperb = body.add_element("div")
upperb.attributes["id"] = "upperbar"
rollerc = upperb.add_element("span")
rollerc.text = "RollerCaster"
upperb.add REXML::Text.new(" · ")
upperinf = REXML::Element.new("span")
upperinf.text = "nothing"
upperinf.attributes["id"] = "upperinfo"
upperb.add upperinf
onchr = upperb.add_element("span")
onchr.text = "(on Chromecast)"
onchr.attributes["id"] = "onchromecast"
loc = upperb.add_element("span")
loc.text = "(locally)"
loc.attributes["id"] = "locally"

erroroverlay = body.add_element("div")
erroroverlay.attributes["id"] = "erroroverlay"
errorbox = erroroverlay.add_element("div") 
errorbox.attributes["id"] = "errorbox"
errorhead = errorbox.add_element("h2")
errorp = errorbox.add_element("p")
errorhead.text = "Could not initialize RollerCaster"
errorp.text = "RollerCaster could not be initialized. This means that either you are not using Chrome or Chromium or the Chromecast add on is missing."

receiveroverlay = body.add_element("div")
receiveroverlay.attributes["id"] = "receiveroverlay"
receiverbox = receiveroverlay.add_element("div") 
receiverbox.attributes["id"] = "receiverbox"
receiverhead = receiverbox.add_element("h2")
receiverp = receiverbox.add_element("p")
receiverhead.text = "Could not find Chromecast"
receiverp.text = "RollerCaster could not find your Chromecast, please open the Google Cast options and make sure your Chromecast is powered on. Reload this page when the Chromecast is available."

infooverlay = body.add_element("div")
infooverlay.attributes["id"] = "infooverlay"
infobox = infooverlay.add_element("div") 
infobox.attributes["id"] = "infobox"
infohead = infobox.add_element("h2")
infop = infobox.add_element("p")
infohead.text = "About Rollercaster"
infop.add REXML::Text.new("RollerCaster started as a proof of concept by Mattias Schlenker that it is easily possible to stream media from a local NAS to your Chromecast. Get the code and the documentation at")
infolink = infop.add_element("a") 
infolink.attributes["target"] = "_blank"
infolink.attributes["href"] = "https://github.com/mschlenker/RollerCaster"
infolink.text = "github.com/mschlenker/RollerCaster"
infop.add REXML::Text.new(". Contact me by Email or send my a beer via PayPal:")
infolink = infop.add_element("a") 
infolink.attributes["href"] = "mailto:ms@mattiasschlenker.de"
infolink.text = "ms@mattiasschlenker.de"
infop = infobox.add_element("p")
infop.add_text("If you are a vendor of NAS devices you might contact me to buy a few hours of consulting to include RollerCaster to your devices.")
infoclose = infobox.add_element("div")
infoclose.attributes["id"] = "infoclose"
infoclose.text = "[close]"

mainvid = body.add_element("div")
mainvid.attributes["id"] = "main_video"
imagesub = mainvid.add_element("div") 
imagesub.attributes["class"] = "imageSub" 
d = imagesub.add_element("div")
d.attributes["class"] = "blackbg"
d.attributes["id"] = "playerstatebg"
d.text = "IDLE"
d = imagesub.add_element("div")
d.attributes["class"] = "label"
d.attributes["id"] = "playerstate"
d.text = "IDLE"
d = imagesub.add_element("img")
d.attributes["src"] = "images/bunny.jpg"
d.attributes["id"] = "video_image"
d = imagesub.add_element("div")
d.attributes["id"] = "video_image_overlay"
v = imagesub.add_element("video")
v.attributes["id"] = "video_element"

mediacontrol = mainvid.add_element("div")
[ "play", "pause", "progress_bg", "progress", "progress_indicator", "fullscreen_expand", "fullscreen_collapse", "casticonactive", "casticonidle", "audio_bg", "audio_bg_track", "audio_indicator", "audio_bg_level", "audio_on", "audio_off", "duration" ].each { |x|
	y = mediacontrol.add_element("div")
	y.attributes["id"] = x 
}

medialist = body.add_element("div")
medialist.attributes["id"] = "medialist" 
scrpt = body.add_element("script")
scrpt.attributes["type"] = "text/javascript"
scrpt.text = "var CastPlayer = new CastPlayer();"
x.print_xml(baseurl, medialist)

doc.write( $stdout, 4 )
