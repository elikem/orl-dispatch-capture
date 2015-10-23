# whenever -f schedule.rb -w

every 5.minutes do
  command "ruby #{File.expand_path(File.dirname(__FILE__))}/orl-dispatch-capture.rb"
end
