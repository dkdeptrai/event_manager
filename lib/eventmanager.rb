# frozen_string_literal: true

require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')
end

def clean_phonenumber(phone_number)
  num_only = ''
  phone_number.split('').each do |char|
    num_only += char if char.match?(/[[:digit:]]/)
  end
  return num_only if num_only.length == 10 || (num_only.length == 11 && num_only[0] == 1)

  'bad'
end

def legislator_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    legislators = civic_info.representative_info_by_address(address: zip, levels: 'country', roles: ['legislatorUpperBody', 'legislatorLowerBody'])
    legislators.officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def get_hour(time)
  valid_time = Time.strptime(time, '%m/%d/%y %k:%M')
  valid_time.hour
end

def get_day(time)
  valid_time = Time.strptime(time, '%m/%d/%y %k:%M')
  Date.new(valid_time.year, valid_time.month, valid_time.day).wday
end

def popular_hours_freq(contents)
  hours_w_freq = Hash.new(0)
  contents.each do |row|
    hours_w_freq[get_hour(row[:regdate])] += 1
  end
  hours_w_freq.sort_by { |_, v| v }.reverse[0..2]
end

def popular_day(contents)
  days_with_freq = Hash.new(0)
  contents.each do |row|
    days_with_freq[Date::DAYNAMES[get_day(row[:regdate])]] += 1
  end
  days_with_freq.max_by { |_, v| v }
end

def save_thankyou_letters(contents)
  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislator_by_zipcode(zipcode)
    form_letter = erb_template.result(binding)
    Dir.mkdir('output') unless Dir.exist?('output')
    file_name = "output/thank_letter_#{id}.html"
    File.open(file_name, 'w') { |file| file.puts form_letter }
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

# save_thankyou_letters(contents)

p popular_day(contents)