require 'rubygems'
require 'bundler'
require 'active_support/core_ext'
Bundler.setup

require 'sinatra'

get "/" do
  flights_hash, airports = get_flight_data()
  
  #the cheapest and fastest flights
  all_flights = []
  best_flights = []
  
  (0..airports).each do |num|
    #complete flight details
    complete_flights = []
    
    #Grab Airport flights that don't return the the starting point
    flights = flights_hash.find_all {|flight| flight[:airport] == num and flight[:end] != 'A' and flight[:start] != 'Z '}
    
    #Get direct flights
    direct_flights = flights.find_all {|flight| flight[:start] == 'A' and flight[:end] == 'Z'}
    direct_flights.each {|flight| 
      complete_flights << flight
      #remove direct flights
      flights.delete(flight)
    }
    
    #nondirect flight trips
    starting_flights = flights.find_all {|f| f[:start] == 'A'}
    complete_flights = flight_options(starting_flights, complete_flights, num)
    all_flights << complete_flights.sort_by {|f| f[:price].to_f}
    
    #cheapest flights
    cheap = complete_flights.min_by {|f| f[:price].to_f}
    cheap_flights = complete_flights.find_all{|f| f[:price] == cheap[:price]}
    best_flights << cheap_flights.min_by {|f| f[:arrival] - f[:departure]}
    
    #shortest flights
    short = complete_flights.min_by {|f| f[:arrival] - f[:departure]}
    short_flights = complete_flights.find_all{|f| (f[:arrival] - f[:departure]) == (short[:arrival] - short[:departure])}
    best_flights << short_flights.min_by {|f| f[:price].to_f}

   end
  
  
  @total = best_flights
  @all = all_flights
  
  erb :total
end

def get_flight_data
  lines = []
  File.open("public/input.txt").each do |line|
      lines << line.chomp unless line.chomp.empty?
  end
  
  #Grab the total airports
  port_num = lines.shift
  airports = port_num.to_i - 1
  flights_by_port = []
  
  #Grab all the flights by Airport
  (0..airports).each do 
    flights = lines.shift.to_i
    flight_details = []
    (1..flights).each do
      flight_details << lines.shift
    end
    flights_by_port << flight_details
  end
  
  flights_hash = []
  
  #Loop through flights by port
  flights_by_port.each_with_index do |flights, i|
    flights.each do |flight|
       #Flight Details
       start, finish, flight_time, arrival, cost = flight.split
       #Parse departure time
       hour, minute = flight_time.split(':')
       departure_time = Time.mktime(2011, "jan", 1, hour, minute)
       #Parse Arrival time
       hour, minute = arrival.split(':')
       arrival_time = Time.mktime(2011, "jan", 1, hour, minute)
       data = {:airport => i, :start => start, :end => finish, :departure => departure_time, :arrival => arrival_time, :price => cost}
       flights_hash << data
    end
  end
  
  return flights_hash, airports
end

def flight_options(flight_array, complete_flights, num)
  #alternative routes
  alternatives = []
  
  #Flight options
  flights_hash, airports = get_flight_data()
  flights = flights_hash.find_all {|flight| flight[:airport] == num and flight[:end] != 'A'}
  
  flight_array.each do |flight|  
    trips = flights.find_all {|f| f[:start] == flight[:end] and f[:departure] >= flight[:arrival]}
    trips.each do |trip|
      data = {:airport => num,
              :start => 'A', 
              :end => trip[:end], 
              :departure => flight[:departure], 
              :arrival => trip[:arrival], 
              :price => trip[:price].to_f + flight[:price].to_f}
      if trip[:end] == 'Z'
        complete_flights << data
      else
        if trip[:arrival] > flight[:arrival]
          alternatives << data
        end
      end
    end
  end
  if !alternatives.empty?
    flight_options(alternatives, complete_flights, num)
  else
    return complete_flights
  end
end