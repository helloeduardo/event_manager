require "csv"
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(homephone)
  number = homephone.delete("^0-9")
  if number.length < 10 || number.length > 11
    "0000000000"
  elsif number.length == 11 && number[0] != "1"
    "0000000000"
  elsif number.length == 11 && number[0] == "1"
    number.delete_prefix("1")
  else
    number
  end
end

def parse_hour(datetime)
  parsed_time = DateTime.strptime(datetime, '%m/%d/%y %H:%M')
  parsed_time.hour
end

def peak_reg_hour(hours)
  hour_frequency = Hash.new(0)

  hours.each do |hour|
    hour_frequency[hour] += 1
  end

  hour_frequency = hour_frequency.sort_by { |hour, tally| tally }

  hour_frequency.each do |hour, tally|
    puts "#{tally} people registered during #{hour}:00"
  end
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
                             address: zipcode,
                             levels: 'country',
                             roles: ['legislatorUpperBody', 'legislatorLowerBody']
                           ).officials

  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

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

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

#iteration: time targeting
hour_data = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  homephone = clean_phone_number(row[:homephone])

  hour_data << parse_hour(row[:regdate])

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

peak_reg_hour(hour_data.sort)
