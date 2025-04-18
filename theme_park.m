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
    % PARK_CAPACITY = 1000;             % Maximum guests allowed in the park at any time
    Y_AXIS_LIMIT = 50;
    RIDE_CAPACITIES = [12 10 15 12 10]; % Number of riders per service
    RIDE_DURATION = 5/60;               % Duration of each ride (hours), includes loading and unloading

    % Initialize State Variables
    rides = categorical({'Carousel', 'Scrambler', 'Teacups', 'Coaster', 'Dark Ride'});
    standby = zeros(1, NUM_RIDES);          % Standby line lengths
    busy = false(1, NUM_RIDES);             % Busy flags for each ride
    Q = [];
    guests_in_park = 0;                     % Number of people in the park currently
    gate = 0;                               % Length of gate queue
    gate_attendant_busy = false;            % Gate attendant busy flag

    % Timing Variables
    time = 0;                               % Simulation clock
    next_arrival_time = expon(1/lambda(0)); % Initial next arrival time AT GATE
    next_admission_time = inf;              % Initial next admission AT GATE
    next_departure_time = inf;              % Initial next departure time from the PARK
    next_ride_times = inf(1, NUM_RIDES);    % Times when next rides will complete

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
        next_event_time = min([next_arrival_time, next_admission_time, next_departure_time, next_ride_times ]);

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

            if gate > 0
                next_admission_time = time + expon(MU);         % Schedule next guest admission
            else
                gate_attendant_busy = false;                    % No more guests to admit
                next_admission_time = inf;
            end

            % Choose a ride and join the queue
            chosen_ride = randi(NUM_RIDES);                     % Randomly select a ride
            standby(chosen_ride) = standby(chosen_ride) + 1;    % Increment the queue length

            % Check if the ride can start immediately
            if ~busy(chosen_ride) && standby(chosen_ride) >= RIDE_CAPACITIES(chosen_ride)
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

                % Guest leaves the park with 1/5 probability
                if rand <= 0.4 % TODO: Update this logic by assigning guests IDs and storing their data. Need to have FIFO queues, makbe write to file.

                    guests_in_park = guests_in_park - 1;

                % Guest decides to go on another ride
                else
                    
                    % Randomly select a ride
                    chosen_ride = randi(NUM_RIDES);                     
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

end

% Time dependent lambda function
function l = lambda(time)
    peakTime = 2;           % Peak time 2 hours after opening
    lambdaMax = 100;         % Maximum rate at peak time
    lambdaMin = 0;         % Minimum rate
    width = 3;              % Controls the spread of the peak
    l = lambdaMin + (lambdaMax - lambdaMin) * exp(-((time - peakTime)^2)/(2*width^2));
end

% Exponential distribution function
function e = expon(mean)
    e = -log(rand) * mean;
end