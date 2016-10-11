require 'open-uri'
require 'crack'
require 'nokogiri'
require 'awesome_print'
require 'active_support/all'
require 'fileutils'

class Capture
  def parse_source_time(time)
    # Example input `10/10/2016 14:25`
    localtime = ActiveSupport::TimeZone["America/New_York"].parse(time)
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

  def formatter
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
    incidents = formatter
    filename = Time.now.utc.strftime('%Y-%M-%e_%H-%M-%S_UTC') + '.csv'

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

    path.first
  end
end

Capture.new.incidents_to_file