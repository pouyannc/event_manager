require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

day_strings = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number.gsub!((/\D/), '')

  if phone_number.length == 11 && phone_number[0] == '1'
    phone_number = phone_number[1..-1]
  elsif phone_number.length != 10
    phone_number = 'Invalid phone number'
  else
    phone_number
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def display_highest_reg_freq(freq_hash)
  freq_hash.sort_by {|k, v| -v}.each_with_index do |pair, i|
    break if i == 5
    puts "#{i + 1}. #{pair[0]} - #{pair[1]} registration(s)"
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

hour_registered = Hash.new(0)
day_registered = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  time = Time.strptime(row[:regdate], '%m/%d/%y %H:%M')
  hour_registered["#{time.hour}:00"] += 1
  day_registered[day_strings[time.wday]] += 1

  legislators = legislators_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)
end

puts "The hours with the most registrations are:"
display_highest_reg_freq(hour_registered)

puts "The days with the most registrations are:"
display_highest_reg_freq(day_registered)