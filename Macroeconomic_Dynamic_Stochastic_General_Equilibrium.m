% ==========================================================
% CARTER & STERLING — QUANTITATIVE RESEARCH & ENGINEERING
% ==========================================================
% Project: DSGE State-Space Modeling & Kalman Filtering
% Author: Abzhamiev Bekdaulet, CEO
% Environment: GNU Octave
% ==========================================================

clear all; close all; clc;

disp('--- Carter & Sterling: Initializing DSGE & Kalman Filter ---');

%% 1. Определение пространства состояний (Linearized State-Space Model)
disp('1. Defining Macroeconomic State-Space Matrices (A, B, C, D)...');
% Вектор состояний x_t = [Output Gap; Inflation; Interest Rate]

% Матрица перехода A (структурные связи экономики)
% Строка 1 (IS Curve): Разрыв ВВП зависит от прошлого ВВП и ставки
% Строка 2 (Phillips Curve): Инфляция зависит от прошлого ВВП и инфляции
% Строка 3 (Taylor Rule): Ставка зависит от ВВП, инфляции и прошлой ставки
A = [ 0.80,  0.05, -0.20;
      0.15,  0.90,  0.00;
      0.10,  0.30,  0.70 ];

% Матрица входа B (Шок монетарной политики ЦБ бьет прямо по ставке)
B = [ 0;
      0;
      1 ];

% Матрица наблюдения C (Мы видим только Инфляцию и Ставку, ВВП - скрыт)
C = [ 0, 1, 0;
      0, 0, 1 ];

% Матрица прямого обхода D (нулевая)
D = [ 0;
      0 ];

%% 2. Расчет Импульсных Функций Отклика (Impulse Response Functions - IRF)
disp('2. Simulating Impulse Response to a 100 bps Monetary Shock...');
periods = 20; % Горизонт 20 кварталов
irf_states = zeros(3, periods);

% Инициализируем шок в t=1 (ЦБ неожиданно повышает ставку на 1%)
shock = 1;
irf_states(:, 1) = B * shock;

% Цикл развития шока (возврат системы к равновесию)
for t = 2:periods
    irf_states(:, t) = A * irf_states(:, t-1);
end

%% 3. Симуляция реальной экономики (Генерация данных для Калмана)
disp('3. Generating noisy economic data with unobserved Output Gap...');
T = 100; % 100 кварталов (25 лет) данных
true_states = zeros(3, T);
measurements = zeros(2, T); % То, что видит Росстат/Бюро статистики

% Ковариационные матрицы шума
Q = eye(3) * 0.02; % Шум процесса (структурные шоки экономики)
R = eye(2) * 0.10; % Шум измерений (ошибки сбора статистики)

% Генерируем реальную траекторию
for t = 2:T
    % x_{t} = A * x_{t-1} + process_noise
    true_states(:, t) = A * true_states(:, t-1) + (randn(3, 1) .* diag(Q));

    % y_{t} = C * x_{t} + measurement_noise
    measurements(:, t) = C * true_states(:, t) + (randn(2, 1) .* diag(R));
end

%% 4. Инициализация и цикл Фильтра Калмана (Kalman Filter)
disp('4. Running Recursive Kalman Filter for state estimation...');
% Начальные предположения (Prior)
x_est = zeros(3, T);       % Оцененные состояния
x_est(:, 1) = [0; 0; 0];   % Начинаем с нуля
P = eye(3);                % Начальная матрица ковариации ошибок (высокая неуверенность)

for t = 2:T
    % --- ШАГ ПРЕДСКАЗАНИЯ (Predict) ---
    x_pred = A * x_est(:, t-1);       % Экстраполяция состояния
    P_pred = A * P * A' + Q;          % Экстраполяция ковариации ошибки

    % --- ШАГ ОБНОВЛЕНИЯ (Update) ---
    y_actual = measurements(:, t);    % Текущие "зашумленные" данные статистики
    y_pred = C * x_pred;              % То, что мы ожидали увидеть
    innovation = y_actual - y_pred;   % Ошибка предсказания

    % Расчет Коэффициента Усиления Калмана (Kalman Gain)
    S = C * P_pred * C' + R;          % Ковариация инновации
    K = P_pred * C' * inv(S);         % Усиление Калмана

    % Корректировка оценки на основе нового измерения
    x_est(:, t) = x_pred + K * innovation;

    % Обновление ковариации ошибки
    P = (eye(3) - K * C) * P_pred;
end

%% 5. Визуализация (Executive Plots)
disp('5. Generating Executive Charts...');
figure('Position', [100, 100, 1000, 800]);

% Сабплот 1: IRF Монетарного Шока
subplot(2, 1, 1);
plot(1:periods, irf_states(1, :), 'b-', 'LineWidth', 2); hold on;
plot(1:periods, irf_states(2, :), 'r-', 'LineWidth', 2);
plot(1:periods, irf_states(3, :), 'k--', 'LineWidth', 2);
title('Carter & Sterling: Impulse Response to Monetary Policy Shock', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Quarters after Shock', 'FontSize', 10);
ylabel('Deviation from Steady State (%)', 'FontSize', 10);
legend('Output Gap (ВВП)', 'Inflation (Инфляция)', 'Interest Rate (Ставка)', 'Location', 'best');
grid on; hold off;

% Сабплот 2: Фильтр Калмана - Оценка скрытого разрыва ВВП
subplot(2, 1, 2);
time_vec = 1:T;
plot(time_vec, true_states(1, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5); hold on;
plot(time_vec, x_est(1, :), 'b-', 'LineWidth', 2);
title('Kalman Filter Estimation of Unobserved Output Gap', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time (Quarters)', 'FontSize', 10);
ylabel('Output Gap', 'FontSize', 10);
legend('True Output Gap (Hidden)', 'Kalman Filter Estimate', 'Location', 'best');
grid on; hold off;

disp('--- Execution Completed ---');
