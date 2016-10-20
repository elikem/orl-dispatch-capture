require 'open-uri'
require 'crack'
require 'nokogiri'
require 'awesome_print'
require 'active_support/all'
require 'fileutils'
require 's3_uploader'
require './environment'

class Capture
  def parse_source_time(time)
    # Example input `10/15/2016 14:25`
    localtime = ActiveSupport::TimeZone["America/New_York"].strptime(time, '%m/%d/%Y %H:%M')
    utc_time = localtime.in_time_zone("UTC")
  end

  def parse
    # Returns an array of hashes with incidents
    feed = 'http://www1.cityoforlando.net/opd/activecalls/'
    incidents = []
    page = Nokogiri::HTML(open(feed))
    calls = Crack::XML.parse(page.xpath('/html/body/calls').to_s)

    calls['calls']['call'].each do |call|
      incidents << {'date' => parse_source_time(call['date']), 'incident_number' => call['incident'], 'desc' => call['desc'].strip, 'location' => call['location'].strip, 'district' => call['district']}
    end

    incidents
  end

  def formatted_incidents
    # Returns an array formatted for file output
    incidents = ['date, incident_number, desc, location, district']

    parse.each do |incident|
      values = []
      incident.each {|k,v| values << v}
      incidents << values.join(', ')
    end

    incidents
  end

  def incidents_to_file
    # Write formatted incidents to files
    time = Time.now.utc
    incidents = formatted_incidents
    filename = "#{time.year}-#{time.month}-#{time.day}-#{time.hour}-#{time.min}-#{time.sec}-UTC" + '.csv'

    puts filename

    File.open(filepath + filename, 'w') do |f|
      incidents.each {|line| f.puts line}
    end
  end

  def filepath
    # Filepath signature
    # Year > Month > Day > Hour
    # 2016 > 10 > 16 > 02

    time = Time.now.utc
    path = FileUtils.mkdir_p "#{File.dirname(__FILE__)}/incidents/#{time.year}/#{time.month}/#{time.day}/#{time.hour}/"

    File.expand_path(path.first) + '/'
  end

  def s3path
    time = Time.now.utc
    path = "#{time.year}/#{time.month}/#{time.day}/#{time.hour}/"
  end

  # uploader.upload('/folder_path_to_upload', 's3_bucket_name', 's3_storage_path/')
  def upload(folder_to_upload, s3_upload_path)
    uploader = S3Uploader::Uploader.new({
                                            :s3_key => ENV['AWS_KEY'],
                                            :s3_secret => ENV['AWS_SECRET'],
                                            :destination_dir => 'orl-pol-dispatch/' + s3_upload_path,
                                            :threads => 10
                                        })

    uploader.upload(folder_to_upload, 'emergency-dispatch')
  end
end

Capture.new.incidents_to_file
Capture.new.upload(Capture.new.filepath, Capture.new.s3path)