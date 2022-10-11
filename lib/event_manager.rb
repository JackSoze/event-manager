require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[LegislatorUpperBody LegislatorLowerBody]
    ).officials

    legislator_names = legislators.map(&:name).join(',')
  rescue StandardError
    puts 'find your rep names online please'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  if phone_number.strip.gsub(/[().-]/, '').nil?
    phone_number
  else
    phone_number = phone_number.strip.gsub(/[().-]/, '')
  end
  if phone_number.length < 10 || phone_number.length > 11
    phone_number = nil
  elsif phone_number.length == 11
    phone_number = (phone_number[1..10] if phone_number.start_with?('1'))
  else
    phone_number
  end
end

def save_popular_regtimes(time_array,days_array)
  Dir.mkdir('advert_info') unless Dir.exist?('advert_info')
  filename = 'advert_info/popular_times.html'
  File.open(filename, 'w') do |filename|
    times = time_array.tally.sort_by { |key, value| -value }
    filename.puts "<h3>DATA FOR HOURS<h3>"
    times.each do |key, value|
      filename.puts "<p>At #{key}00Hrs to #{key + 1}00Hrs: #{value} people registered<p>"
    end
    days = days_array.tally.sort_by { |key, value| -value }
    filename.puts "<h3>DATA FOR HOURS<h3>"
    days.each do |key, value|
      filename.puts("<p>On #{key}s: #{value} people registered<p>")
    end
  end
end

puts 'Event Manager Initialized'

contents = CSV.open('event_attendees.csv',
                    headers: true,
                    header_converters: :symbol)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

time_array = []
days_array = []

contents.each do |row|
  id = row[0]

  name = row[:first_name]

  time = row[:regdate]

  time_object = Time.strptime("#{time}", '%m/%d/%Y %k:%M')

  days_array.push(time_object.strftime("%A"))

  time_array.push(time_object.hour)

  phone_number = clean_phone_number(row[:homephone].to_s.delete(' '))

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

save_popular_regtimes(time_array, days_array)

