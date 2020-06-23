require "csv"

puts 'Event Manager Initialized!'

#basic reading of file and printing names
#does not account for unsupported nuances in csv file format
# lines = File.readlines "event_attendees.csv"
# lines.each_with_index do |line, index|
#   next if index == 0
#   columns = line.split(",")
#   name = columns[2]
#   puts name
# end

contents = CSV.open "event_attendees.csv", headers: true
contents.each do |row|
  name = row[2]
  puts name
end
