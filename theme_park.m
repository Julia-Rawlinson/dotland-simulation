% Theme Park Simulation
% Created by: Julia Rawlinson & Jameson Hoang
% Course: INFO48874 - Simulation and Visualization

clear;
clc;
close all;

main();

function main()   

    % Define Constants
    NUM_RIDES = 5;                      % Number of rides
    MAX_TIME = 12;                      % Length of the simulation in hours
    MU = 1/60;                          % Average processing time at the gate (hours)
    Y_AXIS_LIMIT = 50;
    RIDE_CAPACITIES = [12 10 15 12 10]; % Number of riders per service
    RIDE_DURATION = 5/60;               % Duration of each ride (hours), includes loading and unloading
    AVG = RIDE_CAPACITIES;
    % FASTPASS_LIMIT = 0.75 * AVG;          % Change AVG to the avg number of riders??

    % Initialize State Variables
    rides = categorical({'Carousel', 'Scrambler', 'Teacups', 'Coaster', 'Dark Ride'});
    standby = zeros(1, NUM_RIDES);          % Standby line lengths
    busy = false(1, NUM_RIDES);             % Busy flags for each ride
    % fastpass_q = zeros(1, NUM_RIDES);       % Fastpass queue lengths

    guests_in_park = 0;                     % Number of people in the park currently
    gate = 0;                               % Length of gate queue
    gate_attendant_busy = false;            % Gate attendant busy flag
    
    total_guests = 0;
    % fastpass_status = zeros(1, 1000);   % Initialize fastpass status flags for 1000 guests, adjust afterwards to match how many are needed
    % fastpass_returnTime = zeros(1, 1000);
    % fastpass_count = zeros(1, NUM_RIDES);   % Actual number of FastPasses issued

    % Timing Variables
    time = 0;                               % Simulation clock
    next_arrival_time = expon(1/lambda(0)); % Initial next arrival time AT GATE
    next_admission_time = inf;              % Initial next admission AT GATE
    next_departure_time = inf;              % Initial next departure time from the PARK
    next_ride_times = inf(1, NUM_RIDES);    % Times when next rides will complete

    % Create table for guest management
    max_guests = 1000; % Define the maximum number of guests expected
    guest_data = table((1:max_guests)', false(max_guests, 1), NaN(max_guests, 1), NaN(max_guests, 1), zeros(max_guests, 1), zeros(max_guests, 1), 'VariableNames', {'Guest_ID', 'FastPass', 'ReturnTime', 'LastEntryTime', 'TotalWaitTime', 'RidesTaken'});
    guest_id = inf;

    % Create Plot
    h = figure;
    % bar = bar(rides, vertcat(standby, fastlane)','grouped');

    % Un-comment these to see the lineup at the gate
    % gate_bar_graph = bar(gate);
    % title('Entrance Queue Length at DotLand');
    % xlabel('Time (hours)');
    % ylabel('Queue Length');
    % ylim([0 Y_AXIS_LIMIT]); 
    % arrival_rate_label = text(0.5, Y_AXIS_LIMIT - 5, '', 'FontSize', 10);

    rides_bar_graph = bar(rides, standby);
    title('Standby Line Lengths at Dotland');
    xlabel('Time (hours)');
    ylabel('Queue Length');
    ylim([0 Y_AXIS_LIMIT]); 
    total_guests_label = text(0.5, Y_AXIS_LIMIT - 15, '', 'FontSize', 10);

    % Begin main loop - simulates one day at the park
    while time < MAX_TIME

        % Determine next event time
        next_event_time = min([next_arrival_time, next_admission_time, next_departure_time, next_ride_times]);

        % Update time
        time = next_event_time;

        % Simulate next event

        % Customer arrives at gate
        if next_event_time == next_arrival_time

            gate = gate + 1;                                  % Increase gate queue
            next_arrival_time = time + expon(1/lambda(time)); % Set time of next arrival

            % Check if the gate attendant can start serving immediately
            if ~gate_attendant_busy && gate > 0
                gate_attendant_busy = true;
                next_admission_time = time + expon(MU);
            end

        % Customer admitted to the park
        elseif next_event_time == next_admission_time

            gate = gate - 1;                                    % Decrease gate queue length
            guests_in_park = guests_in_park + 1;                % Increase number of guests in park
            guest_id = guests_in_park;

            if gate > 0
                next_admission_time = time + expon(MU);         % Schedule next guest admission
            else
                gate_attendant_busy = false;                    % No more guests to admit
                next_admission_time = inf;
            end     

            % Choose a ride and join the queue
            chosen_ride = randi(NUM_RIDES);                     % Randomly select a ride
            guest_data.LastEntryTime(guest_id) = time;

            % if fastpass_count(chosen_ride) < FASTPASS_LIMIT(chosen_ride)
                
                % Give them a guest a FastPass, (change FastPass status to
                % TRUE)
                % fastpass_status(guest_id) = 1;

                % A time that is between opening and closing in 30 minute
                % intervals
                % randomTime = randi([2, 24]) / 2;
                % fastpass_returnTime(guest_id) = randomTime;

                % fastpass_q(chosen_ride) = fastpass_q(chosen_ride) + 1;
                % fastpass_count(chosen_ride) = fastpass_count(chosen_ride) + 1;

            % else
                % IF there are no more FastPasses available, peasants go to
                % the standby Queue
                standby(chosen_ride) = standby(chosen_ride) + 1;
                
            % end       

            % Check if the ride can start immediately
            % riderTotal = standby(chosen_ride) + fastpass_q(chosen_ride);
            if ~busy(chosen_ride) && standby(chosen_ride) >= RIDE_CAPACITIES(chosen_ride)
            % if ~busy(chosen_ride) && riderTotal >= RIDE_CAPACITIES(chosen_ride)
                busy(chosen_ride) = true;
                next_ride_times(chosen_ride) = time + RIDE_DURATION; % Schedule ride completion time
            end

        % Customers released from a ride
        elseif any(next_event_time == next_ride_times)

            % Identify which ride has finished
            finished_ride = find(next_event_time == next_ride_times); 

            % Process ride completion
            busy(finished_ride) = false; % Ride becomes available
            num_guests_finished = min(standby(finished_ride), RIDE_CAPACITIES(finished_ride));
            standby(finished_ride) = max(standby(finished_ride) - RIDE_CAPACITIES(finished_ride), 0); % Decrement queue

            % If there are enough guests waiting, start the next ride cycle immediately
            if standby(finished_ride) >= RIDE_CAPACITIES(finished_ride)
                busy(finished_ride) = true;
                next_ride_times(finished_ride) = time + RIDE_DURATION; % Schedule next ride completion time
            else
                next_ride_times(finished_ride) = inf; % No immediate next cycle if not enough guests
            end
            
            % Guests make post ride activity decision 
            for i = 1:num_guests_finished

                % Guest leaves the park with 2/5 probability
                if rand <= 0.4 % TODO: Update this logic

                    guests_in_park = guests_in_park - 1;

                    % Guest returns their FastPass aka more FastPasses
                    % become available
                    % if fastpass_status(guest_id) == 1
                        % fastpass_count(chosen_ride) = max(fastpass_count(chosen_ride)-1, 0);
                    % end

                % Guest decides to go on another ride
                else
                    
                    % Randomly select a ride
                    chosen_ride = randi(NUM_RIDES);                     

                    % Check again for FastPass limits
                    % if fastpass_count(chosen_ride) < FASTPASS_LIMIT(chosen_ride)
                        %fastpass_status(guest_id) = 1;
                        %fastpass_q(chosen_ride) = fastpass_q(chosen_ride) + 1;
                        %fastpass_count(chosen_ride) = fastpass_count(chosen_ride) + 1;
                    %end

                    standby(chosen_ride) = standby(chosen_ride) + 1;    % Increment the queue length for the next ride

                    % Check if the next ride can start immediately
                    if ~busy(chosen_ride) && standby(chosen_ride) >= RIDE_CAPACITIES(chosen_ride)
                        busy(chosen_ride) = true;
                        next_ride_times(chosen_ride) = time + RIDE_DURATION; % Schedule next ride completion time
                    end

                end

            end

        end

        % Update visualization
        % set(gate_bar_graph, 'YData', gate);
        % clockTime = 8 + time; % Park opens at 8 AM
        % hours = floor(clockTime);
        % minutes = floor((clockTime - hours) * 60);
        % xlabel(['Time: ', sprintf('%02d:%02d', hours, minutes)]); % Update the x-axis label with clock time
        % set(arrival_rate_label, 'String', ['Arrival Rate: ', num2str(lambda(time), '%.2f'), ' guests/hour']); % Update arrival rate text
        % drawnow;

        set(rides_bar_graph, 'YData', standby);
        clockTime = 8 + time; % Park opens at 8 AM
        hours = floor(clockTime);
        minutes = floor((clockTime - hours) * 60);
        xlabel(['Time: ', sprintf('%02d:%02d', hours, minutes)]); % Update the x-axis label with clock time
        set(total_guests_label, 'String', ['Total Guests in Park: ', num2str(guests_in_park)]); 
        drawnow;
        
    end
    
    % Export guest information to excel file
    writetable(guest_data, 'guest_data.csv');

end

% Time dependent lambda function
function l = lambda(time)
    peakTime = 2;           % Peak time 3 hours after opening
    lambdaMax = 100;         % Maximum rate at peak time
    lambdaMin = 0;         % Minimum rate
    width = 3;              % Controls the spread of the peak
    l = lambdaMin + (lambdaMax - lambdaMin) * exp(-((time - peakTime)^2)/(2*width^2));
end

% Exponential distribution function
function e = expon(mean)
    e = -log(rand) * mean;
end