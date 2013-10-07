#!/usr/bin/env ruby

# Harvest format http://www.getharvest.com/help/account-settings/managing-account-settings/importing-and-exporting-data
# Date (YYYY-MM-DD or M/D/YYYY formats. For example: 2008-08-25 or 8/25/2008)
# Client
# Project
# Task
# Note
# Hours (in decimal form, without any stray characters. For example: 7.5, 3, 9.9)
# First name
# Last name

# Toggl format
# User,Email,Client,Project,Task,Description,Billable,Start date,Start time,End date,End time,Duration,Tags,Amount

require 'csv'
require 'date'

def is_header_row(row_array)
	row_array[0] == "User"
end

def get_toggl_value( field_name, row_array )
	toggl_fields = %w( User Email Client Project Task Description Billable Startdate Starttime Enddate Endtime Duration Tags Amount )
	index = toggl_fields.index( field_name )
	row_array[ index ]
end 

input_file_name  = ARGV[0]
output_file_name = input_file_name.gsub(".csv", "_harvest.csv")

harvest_rows = []
harvest_rows.push %w( Date Client Project Task Note Hours First\ Name Last\ Name )

CSV.foreach(input_file_name) do |row|
  unless is_header_row( row )
    date 		= get_toggl_value( "Startdate", row )
    
    duration_hh_mm_ss = get_toggl_value( "Duration", row ).split(":")
    duration_decimal  = sprintf('%0.2f',duration_hh_mm_ss[0].to_f + (duration_hh_mm_ss[1].to_f/60.0))

    client 		= get_toggl_value( "Client", row)
    project 	= get_toggl_value( "Project", row)
    task 		= get_toggl_value( "Task", row)
    note      = get_toggl_value( "Description", row)
    user      = get_toggl_value( "User", row)
    firstname, lastname = user.split(' ', 2)

    next if client.nil? or project.nil?

    if task.nil? 
    	task = "Imported"
    end

    if lastname.nil?
      lastname = "Imported"
    end

    # Date, Client, Project, Task, Note, Hours, Firstname, Lastname
    harvest_rows.push [date, "\"#{client}\"", "\"#{project}\"", "\"#{task}\"", "\"#{note}\"", duration_decimal, "\"#{firstname}\"", "\"#{lastname}\""]
  end
end

# CSV does not support individual quoting of fields so we have to make them ourselves and remove csv's own quoting afterwards
csv = CSV.generate :quote_char => "\0" do |csv|
  harvest_rows.each do |row|
    csv << row
  end
end
csv.gsub!(/\0/, '')


File.open( output_file_name, "wb") do |file|
	file.puts csv
end

puts IO.read(output_file_name)