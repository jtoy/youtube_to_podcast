require 'bundler/setup'
require 'sinatra'
require 'digest'
require 'fileutils'
require 'erb'
require 'rss'
require 'logger'

FileUtils.mkdir_p "content"
FileUtils.mkdir_p "log"
error_log = ::File.new("log/error.log","a+")
error_log.sync = true
before {
  env["rack.errors"] = error_log
}

get '/' do
  if params[:feed]
    md5 = Digest::MD5.hexdigest(params[:feed])
    dir = "content/#{md5}"
    ts = "content/.#{md5}_updated"
    cmd = "youtube-dl --dateafter now-14days --extract-audio --audio-format mp3 --download-archive #{dir} #{params[:feed]}"
    if !File.exists?(ts) || (File.exists?(dir) && File.exists?(ts) && (Time.now - 3600*24) > File.atime(ts))
      FileUtils.touch(ts)
      puts cmd
      Thread.new { puts 'starting download'; r = `#{cmd}`; puts r }
    end
    rss = RSS::Maker.make("atom") do |maker|
      maker.channel.updated = File.atime(ts)
      maker.channel.id = md5
      maker.channel.author = params[:feed]
      maker.channel.title = params[:feed]
      files = Dir.glob("#{dir}*.mp3").reject { |e| File.directory? e }
      files.each do |f|
        maker.items.new_item do |item|
          item.link = f
          item.title = f
        end 
      end
    end
    puts rss
    puts 'DDDD'
    rss
  else
    '<form>feed url:<input name="feed"><input type="submit"></form>'
  end
end

