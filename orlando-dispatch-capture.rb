require 'open-uri'
require 'crack'
require 'nokogiri'
require 'awesome_print'

class Capture
  def parse
    # Returns an array of hashes with incidents
    feed = 'http://www1.cityoforlando.net/opd/activecalls/'
    incidents = []
    page = Nokogiri::HTML(open(feed))
    calls = Crack::XML.parse(page.xpath('/html/body/calls').to_s)

    calls['calls']['call'].each do |call|
      incidents << {'date' => call['date'], 'incident_number' => call['incident'], 'desc' => call['desc'].strip, 'location' => call['location'].strip, 'district' => call['district']}
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

  def to_file
    # Write formatted incidents to files
    incidents = formatter
    filename = Time.now.utc.strftime('%Y-%M-%e_%H-%M-%S_UTC') + '.csv'

    File.open(filepath + filename, 'w') do |f|
      incidents.each {|line| f.puts line}
    end
  end

  def filepath
    "#{File.dirname(__FILE__)}/incidents/"
  end
end

Capture.new.to_file