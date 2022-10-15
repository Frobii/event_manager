require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'
require 'colorize'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.delete("^0-9").to_s.split("")

  if phone_number.length == 10
    phone_number.join("")
  elsif phone_number.length == 11 && phone_number[0] == "1"
    phone_number.slice!(0)
    phone_number = phone_number.join("")
  else
    return "bad number".red
  end
end

def return_hour(time)
  time = time.split(" ")
  time = Time.parse(time[1])
  time.strftime("%k")
end

def return_day(time)
  def number_to_day(number)
    if number == 0
      return "Sunday"
    elsif number == 1
      return "Monday"
    elsif number == 2
      return "Tuesday"
    elsif number == 3
      return "Wednesday"
    elsif number == 4
      return "Thursday"
    elsif number == 5
      return "Friday"
    elsif number == 6
      return "Saturday"
    end
  end

  time = time.split(" ")
  date = time[0]
  date = date.split("/")
  number_to_day(Date.new(("20" + date[2]).to_i, date[0].to_i, date[1].to_i).wday)
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
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'
puts "\n"

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('../form_letter.erb')
erb_template = ERB.new template_letter

time_of_submission = []

day_of_submission = []

contents.each do |row|
  id = row[0]

  name = row[:first_name]
  phone_number = row[:homephone]
  zipcode = row[:zipcode]
  time = row[:regdate]

  zipcode = clean_zipcode(zipcode)

  phone_number = clean_phone_number(phone_number)
  
  time_of_submission.push(return_hour(time))

  day_of_submission.push(return_day(time))

  puts "#{phone_number} - #{name}"

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

puts "\n"
puts time_of_submission.max_by { |i| time_of_submission.count(i) } + ":00 is the most frequent registration hour"
puts day_of_submission.max_by { |i| day_of_submission.count(i) } + " is the most frequent registration day"
