

clc; clear; close all;

%% **Step 1: Define System Parameters**
T_chiller = 500; % Chiller tonnage (tons)
COP_base = 3.5; % Baseline COP (without geothermal)
COP_geothermal = 7.0; % Improved COP with geothermal heat rejection
H = 4000; % Annual operating hours

% Hot Water Tank Parameters
tank_capacity = 500; % Liters of water in tank
water_temp_initial = 60; % Initial temperature in Celsius
heat_capacity_water = 4.2; % kJ/kg°C (specific heat of water)
heat_recovery_efficiency = 0.7; % 70% heat recovery efficiency

% Time-of-Use (TOU) Electricity Pricing ($/kWh)
TOU_rates = [0.10 0.12 0.15 0.20 0.25 0.30 0.28 0.25 0.20 0.18 0.15 0.12 ...
             0.10 0.10 0.12 0.15 0.18 0.22 0.28 0.30 0.25 0.18 0.12 0.10]';

% Chiller Load Variation (24-Hour Cycle)
time_hours = (0:23)'; % Time of day
load_variation = [0.6 0.5 0.4 0.4 0.5 0.7 0.9 1.0 1.0 0.9 0.8 0.8 ...
                  0.7 0.7 0.8 0.9 1.0 1.0 0.9 0.8 0.7 0.6 0.6 0.6]';

%% **Step 2: Geothermal Heat Rejection & Hot Water Tank Heat Recovery**
geothermal_efficiency = 0.75; % 75% efficiency from geothermal rejection
heat_recovery = (T_chiller * load_variation / COP_geothermal) * heat_recovery_efficiency;

% Adjust Water Temperature in Hot Water Tank
water_temp_change = (heat_recovery * 3600) ./ (tank_capacity * heat_capacity_water); % °C increase per hour
water_temp_final = water_temp_initial + sum(water_temp_change) / 24;

%% **Step 3: AI-Based Load Prediction for Optimization**
% Normalize Input Data for AI Model
load_input_min = min(time_hours);
load_input_max = max(time_hours);
load_output_min = min(load_variation);
load_output_max = max(load_variation);

load_input_norm = (time_hours - load_input_min) / (load_input_max - load_input_min);
load_output_norm = (load_variation - load_output_min) / (load_output_max - load_output_min);

% Ensure Row Vector Format
load_input_norm = load_input_norm'; 
load_output_norm = load_output_norm'; 

% Train Neural Network for Load Prediction
net = feedforwardnet(10, 'trainlm');
net.trainParam.showWindow = false;
[net, tr] = train(net, load_input_norm, load_output_norm);

% Predict Future Load Using AI
future_load_norm = net(load_input_norm);
future_load = (future_load_norm' * (load_output_max - load_output_min)) + load_output_min;

%% **Step 4: Energy Savings & Financial Analysis**
Capex_base = 120000; % Initial Capital Cost ($)
Capex_reduced = Capex_base * 0.7; % Assume 30% incentives (grants, tax credits, rebates)
Opex = 5000; % Annual Maintenance Cost ($)
Discount_Rate = 0.07; % 7% discount rate
Years = 15; % Analysis period

% Compute Total Energy Savings
E_base = (T_chiller * load_variation) / COP_base; % Baseline energy usage
E_hybrid = ((T_chiller * load_variation) ./ COP_geothermal) - geothermal_efficiency;
Delta_E = E_base - E_hybrid;
E_saved_total = sum(Delta_E) * H / 24; % Total energy savings (kWh per year)
Cost_Savings = sum(Delta_E .* TOU_rates) * H / 24; % Total cost savings

% Compute NPV & Payback Period
Cash_Flows = [-Capex_reduced, repmat(Cost_Savings - Opex, 1, Years)];
NPV_value = sum(Cash_Flows ./ (1 + Discount_Rate).^(0:Years));
IRR_value = irr(Cash_Flows);
Payback_period = Capex_reduced / Cost_Savings;

%% **Step 5: Display Results**
fprintf('\n=== AI + Geothermal HVAC System with Hot Water Tank ===\n');
fprintf('Total Energy Savings: %.2f kWh per year\n', E_saved_total);
fprintf('Total Cost Savings: $%.2f per year\n', Cost_Savings);
fprintf('Payback Period: %.2f years\n', Payback_period);
fprintf('NPV (Net Present Value) over %d years: $%.2f\n', Years, NPV_value);
fprintf('IRR (Internal Rate of Return): %.2f%%\n', IRR_value * 100);
fprintf('Final Hot Water Tank Temperature: %.2f°C\n', water_temp_final);
fprintf('Dynamic COP of AI + Geothermal System: %.2f\n', COP_geothermal);

%% **Step 6: Visualization**
figure;

% Load Variation & AI Prediction
subplot(1, 3, 1);
plot(time_hours, load_variation, 'b', 'LineWidth', 2);
hold on;
plot(time_hours, future_load, 'r--', 'LineWidth', 2);
xlabel('Hour of Day'); ylabel('Load Factor');
legend('Actual Load', 'Predicted Load');
title('Chiller Load Variation (AI-Based)'); grid on;

% Energy Savings Over Time
subplot(1, 3, 2);
plot(time_hours, Delta_E, 'g', 'LineWidth', 2);
xlabel('Hour of Day'); ylabel('Energy Savings (kWh)');
title('Hourly Energy Savings'); grid on;

% Heat Rejection Distribution (Geothermal)
subplot(1, 3, 3);
plot(time_hours, heat_recovery, 'c', 'LineWidth', 2);
xlabel('Hour of Day'); ylabel('Heat Energy (kWh)');
title('Geothermal Heat Recovery Efficiency'); grid on;

