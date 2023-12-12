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
    Y_AXIS_LIMIT = 35;
    RIDE_CAPACITIES = [12 15 10 12 10]; % Number of riders per service
    RIDE_DURATION = 5/60;               % Duration of each ride (hours), includes loading and unloading
    FASTPASS_RATIO = 0.6;               % Num passes issued, as a % of hourly capacity
    FASTPASS_LIMIT = round((RIDE_CAPACITIES / RIDE_DURATION) * FASTPASS_RATIO * 12); % Total per ride per day

    % Initialize State Variables
    rides = categorical({'Carousel', 'Scrambler', 'Teacups', 'Coaster', 'Dark Ride'});
    standby = zeros(1, NUM_RIDES);          % Standby line lengths
    busy = false(1, NUM_RIDES);             % Busy flags for each ride
    fastpass = zeros(1, NUM_RIDES);         % Fastpass queue lengths
    guests_in_park = 0;                     % Number of people in the park currently
    gate = 0;                               % Length of gate queue
    gate_attendant_busy = false;            % Gate attendant busy flag
    last_id = 0;                            % Guest ID last issued
    fastpass_count = FASTPASS_LIMIT;   % Array to track available FastPasses

    % Initialize FIFO queues for each lineup type
    standby_ride_queues = cell(NUM_RIDES, 1);
    for i = 1:NUM_RIDES
        standby_ride_queues{i} = [];  % Each cell is an empty array representing a queue
    end

    fastpass_ride_queues = cell(NUM_RIDES, 1);
    for i = 1:NUM_RIDES
        fastpass_ride_queues{i} = [];  % Each cell is an empty array representing a queue
    end

    % Timing Variables
    time = 0;                               % Simulation clock
    next_arrival_time = expon(1/lambda(0)); % Initial next arrival time AT GATE
    next_admission_time = inf;              % Initial next admission AT GATE
    next_departure_time = inf;              % Initial next departure time from the PARK
    next_ride_times = inf(1, NUM_RIDES);    % Times when next rides will complete

    % Create table for guest management
    max_guests = 1000; % Define the maximum number of guests expected
    guest_data = table((1:max_guests)', ...                    % Guest_ID
                   false(max_guests, 1), ...                   % FastPass (boolean)
                   NaN(max_guests, 1), ...                     % FastPassRide (ride # for which they have a FastPass)
                   NaN(max_guests, 1), ...                     % FastPassReturnTime (return time window for FastPass)
                   NaN(max_guests, 1), ...                     % LastEntryTime
                   zeros(max_guests, 1), ...                   % TotalWaitTime
                   zeros(max_guests, 1), ...                   % RidesTaken
                   'VariableNames', {'Guest_ID', ...
                                     'FastPass', ...
                                     'FastPassRide', ...
                                     'FastPassReturnTime', ...
                                     'LastEntryTime', ...
                                     'TotalWaitTime', ...
                                     'RidesTaken'});
    

    % Create Plot
    %h = figure;
    % bar = bar(rides, vertcat(standby, fastlane)','grouped');

    % Un-comment these to see the lineup at the gate over time
    % gate_bar_graph = bar(gate);
    % title('Entrance Queue Length at DotLand');
    % xlabel('Time (hours)');
    % ylabel('Queue Length');
    % ylim([0 Y_AXIS_LIMIT]); 
    % arrival_rate_label = text(0.5, Y_AXIS_LIMIT - 5, '', 'FontSize', 10);

    queue_data = [standby; fastpass]';
    rides_bar_graph = bar(rides, queue_data, 'grouped');
    rides_bar_graph(1).FaceColor = 'green';  
    rides_bar_graph(2).FaceColor = 'magenta';
    title('Queue Lengths at DotLand');
    xlabel('Time (hours)');
    ylabel('Queue Length');
    ylim([0 Y_AXIS_LIMIT]);
    legend('Standby', 'FastPass');
    total_guests_label = text(0.5, Y_AXIS_LIMIT - 3, '', 'FontSize', 10);


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
            guest_id = last_id + 1;                             % IDs issued in order
            last_id = guest_id;

            if gate > 0
                next_admission_time = time + expon(MU);         % Schedule next guest admission
            else
                gate_attendant_busy = false;                    % No more guests to admit
                next_admission_time = inf;
            end     

            % Choose a ride and join the queue
            chosen_ride = randi(NUM_RIDES);                     % Randomly select a ride

            if fastpass_count(chosen_ride) > 0

                % Give the guest a Fastpass
                fastpass_count(chosen_ride) = fastpass_count(chosen_ride) - 1;

                % Update guest Fastpass info
                guest_data.FastPass(guest_id) = true;
                guest_data.FastPassRide(guest_id) = chosen_ride;

                % Calculate appropriate return time window by
                % finding the next time slot where passes are available
                % No return times calculated?
                passes_issued = FASTPASS_LIMIT(chosen_ride) - fastpass_count(chosen_ride);
                time_slot = ceil(passes_issued / (FASTPASS_LIMIT(chosen_ride) / 24));
                return_time = (time_slot - 1) * 0.5;
                guest_data.FastPassReturnTime(guest_id) = return_time;

                % Randomly select a different ride and join the standby queue
                other_ride = randi(NUM_RIDES);
                guest_data.LastEntryTime(guest_id) = time;
                standby_ride_queues{other_ride} = [standby_ride_queues{other_ride}, guest_id];
                standby(other_ride) = standby(other_ride) + 1;

            else 
                % No fastpasses left available, peasants go to standby
                guest_data.LastEntryTime(guest_id) = time;
                standby_ride_queues{chosen_ride} = [standby_ride_queues{chosen_ride}, guest_id];  % Add guest ID to the end of the queue
                standby(chosen_ride) = standby(chosen_ride) + 1;
            end  

            % Check if the ride can start immediately
            rider_total = standby(chosen_ride) + fastpass(chosen_ride);
            % if ~busy(chosen_ride) && standby(chosen_ride) >= RIDE_CAPACITIES(chosen_ride)
            if ~busy(chosen_ride) && rider_total >= RIDE_CAPACITIES(chosen_ride)
                busy(chosen_ride) = true;
                next_ride_times(chosen_ride) = time + RIDE_DURATION; % Schedule ride completion time
            end

        % Customers released from a ride
        elseif any(next_event_time == next_ride_times)

            % Identify which ride has finished
            finished_ride = find(next_event_time == next_ride_times); 
            
            for r = 1:length(finished_ride) % Necessary because sometimes rides let out at the exact same time

            % Process ride completion
            busy(finished_ride(r)) = false; % Ride becomes available

            % num_guests_finished = min(standby(finished_ride(r)), RIDE_CAPACITIES(finished_ride(r)));
            % standby(finished_ride(r)) = max(standby(finished_ride(r)) - RIDE_CAPACITIES(finished_ride(r)), 0); % Decrement queue

            % Calculate the number of guests to process from FastPass queue
            num_fastpass = length(fastpass_ride_queues{finished_ride(r)});
            num_fastpass_to_process = min(num_fastpass, RIDE_CAPACITIES(finished_ride(r)));

            % Calculate remaining capacity for standby guests
            remaining_capacity = RIDE_CAPACITIES(finished_ride(r)) - num_fastpass_to_process;
            num_standby_to_process = min(length(standby_ride_queues{finished_ride(r)}), remaining_capacity);

            % Decrement queue lengths
            standby(finished_ride(r)) = standby(finished_ride(r)) - num_standby_to_process;
            fastpass(finished_ride(r)) = fastpass(finished_ride(r)) - num_fastpass_to_process;

            num_guests_finished = num_standby_to_process + num_fastpass_to_process;
            
            for i = 1:num_guests_finished

                % Dequeue the first guest in the queue
                % guest_id = standby_ride_queues{finished_ride(r)}(1);
                % standby_ride_queues{finished_ride(r)}(1) = [];

                if ~isempty(fastpass_ride_queues{finished_ride(r)})
                    guest_id = fastpass_ride_queues{finished_ride(r)}(1);
                    fastpass_ride_queues{finished_ride(r)}(1) = [];
                elseif ~isempty(standby_ride_queues{finished_ride(r)})
                    guest_id = standby_ride_queues{finished_ride(r)}(1);
                    standby_ride_queues{finished_ride(r)}(1) = [];
                else
                    % Break the loop if both queues are empty
                    break;
                end

                % Update guest data for the disembarking guest
                guest_data.RidesTaken(guest_id) = guest_data.RidesTaken(guest_id) + 1;

                wait_time = max((time - guest_data.LastEntryTime(guest_id)) - RIDE_DURATION, 0);
                guest_data.TotalWaitTime(guest_id) = guest_data.TotalWaitTime(guest_id) + wait_time;
                % ... other updates as needed ... TODO

                % Guest leaves the park with 2/5 probability
                if rand <= 0.4    % TODO: Update this logic
                    
                    guests_in_park = guests_in_park - 1;
                    % Optionally update guest_data to reflect their departure

                % Guest decides to go on another ride
                else
                    % If the guest's fastpass window has arrived, go to that queue
                    if time >= guest_data.FastPassReturnTime(guest_id) && guest_data.FastPass(guest_id)
                        chosen_ride = guest_data.FastPassRide(guest_id);
                        guest_data.LastEntryTime(guest_id) = time;
                        fastpass(chosen_ride) = fastpass(chosen_ride) + 1;
                        fastpass_ride_queues{chosen_ride} = [fastpass_ride_queues{chosen_ride}, guest_id];
                        guest_data.FastPass(guest_id) = false;
                        guest_data.FastPassRide(guest_id) = NaN;
                        guest_data.FastPassReturnTime(guest_id) = NaN;
                    else 
                        % Randomly select a different ride and get in the queue
                        chosen_ride = randi(NUM_RIDES); 
                        guest_data.LastEntryTime(guest_id) = time;
                        standby_ride_queues{chosen_ride} = [standby_ride_queues{chosen_ride}, guest_id];  % Add guest ID to the end of the queue
                        standby(chosen_ride) = standby(chosen_ride) + 1;    % Increment the queue length for the next ride
                    end

                    % Check if the next ride can start immediately
                    rider_total = standby(chosen_ride) + fastpass(chosen_ride);
                    if ~busy(chosen_ride) && rider_total >= RIDE_CAPACITIES(chosen_ride)
                        busy(chosen_ride) = true;
                        next_ride_times(chosen_ride) = time + RIDE_DURATION; % Schedule next ride completion time
                    end

                end

            end

            % If there are enough guests waiting, start the next ride cycle immediately
            if standby(finished_ride(r)) + fastpass(finished_ride(r)) >= RIDE_CAPACITIES(finished_ride(r))
                busy(finished_ride(r)) = true;
                next_ride_times(finished_ride(r)) = time + RIDE_DURATION; % Schedule next ride completion time
            else
                next_ride_times(finished_ride(r)) = inf; % No immediate next cycle if not enough guests
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

        queue_data = [standby; fastpass]';
        set(rides_bar_graph(1), 'YData', queue_data(:, 1));
        set(rides_bar_graph(2), 'YData', queue_data(:, 2));
        clockTime = 8 + time; % Park opens at 8 AM
        hours = floor(clockTime);
        minutes = floor((clockTime - hours) * 60);
        xlabel(['Time: ', sprintf('%02d:%02d', hours, minutes)]); % Update the x-axis label with clock time
        set(total_guests_label, 'String', ['Total Guests in Park: ', num2str(guests_in_park)]); 
        drawnow;
        
    end
    
    % Export guest information to csv file
    writetable(guest_data, 'guest_data.csv');

end

% Time dependent lambda function
function l = lambda(time)
    peakTime = 2;           % Peak time 3 hours after opening
    lambdaMax = 50;         % Maximum rate at peak time
    lambdaMin = 0;         % Minimum rate
    width = 2;              % Controls the spread of the peak
    l = lambdaMin + (lambdaMax - lambdaMin) * exp(-((time - peakTime)^2)/(2*width^2));
end

% Exponential distribution function
function e = expon(mean)
    e = -log(rand) * mean;
end