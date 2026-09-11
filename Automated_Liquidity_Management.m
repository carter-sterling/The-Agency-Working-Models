% ==========================================================
% CARTER & STERLING — QUANTITATIVE RESEARCH & ENGINEERING
% ==========================================================
% Project: Automated Liquidity Management (Discrete PID)
% Author: Abzhamiev Bekdaulet, CEO
% Environment: GNU Octave (Base / No external packages)
% ==========================================================

clear all; close all; clc;

disp('--- Carter & Sterling: Initializing Discrete Treasury PID ---');

%% 1. Параметры времени и симуляции
disp('1. Setting up discrete time simulation...');
dt = 0.05;              % Шаг симуляции (часть дня)
T_end = 15;             % Горизонт симуляции (15 дней)
t = 0:dt:T_end;         % Вектор времени
N = length(t);

%% 2. Инициализация переменных казначейства (State Variables)
disp('2. Initializing State-Space Plant (Cash Dynamics)...');
cash_balance = zeros(1, N);     % y(t)  - Текущий остаток на счетах
cash_rate = zeros(1, N);        % y'(t) - Скорость изменения остатка
u = zeros(1, N);                % u(t)  - Управляющий сигнал (запрос на ликвидность)
error = zeros(1, N);            % e(t)  - Ошибка (Разрыв между фактом и целью)

target_cash = 10; % Целевой неснижаемый остаток: $10 млн (Liquidity Shock)

%% 3. Настройка параметров ПИД-регулятора
disp('3. Tuning Discrete PID Controller...');
Kp = 2.5;   % Пропорциональный коэффициент
Ki = 0.8;   % Интегральный коэффициент
Kd = 1.2;   % Дифференциальный коэффициент

integral_e = 0;   % Накопленная ошибка
prev_error = 0;   % Ошибка на предыдущем шаге

%% 4. Главный цикл симуляции (Euler Integration)
disp('4. Executing Closed-Loop Simulation (Euler Method)...');
for k = 1:N-1
    % --- ШАГ 1: Измерение ошибки (Отклонение от цели) ---
    error(k) = target_cash - cash_balance(k);

    % --- ШАГ 2: Вычисление компонентов ПИД-регулятора ---
    integral_e = integral_e + error(k) * dt;           % I: Интеграл
    derivative_e = (error(k) - prev_error) / dt;       % D: Производная (Градиент)

    % --- ШАГ 3: Формирование управляющего сигнала (Запрос средств) ---
    u(k) = Kp * error(k) + Ki * integral_e + Kd * derivative_e;

    % Запоминаем текущую ошибку для следующего шага
    prev_error = error(k);

    % --- ШАГ 4: Симуляция банковской системы (Plant Dynamics) ---
    % Дифференциальное уравнение инерции банка: 0.5 * y'' + y' = u
    % Преобразуем в систему уравнений первого порядка:
    % 1) d(cash)/dt = cash_rate
    % 2) d(cash_rate)/dt = -2 * cash_rate + 2 * u

    cash_balance(k+1) = cash_balance(k) + dt * cash_rate(k);
    cash_rate(k+1) = cash_rate(k) + dt * (-2 * cash_rate(k) + 2 * u(k));
end

% Заполняем последние значения массивов для ровных графиков
error(N) = target_cash - cash_balance(N);
u(N) = u(N-1);

%% 5. Визуализация (Executive Charts)
disp('5. Generating Institutional Graphics...');
figure('Position', [50, 100, 1100, 500]);

% Сабплот 1: Динамика денежного баланса
subplot(1, 2, 1);
plot(t, cash_balance, 'b', 'LineWidth', 2); hold on;
plot(t, ones(size(t)) * target_cash, 'r--', 'LineWidth', 1.5);
title('Treasury Step Response: $10M Liquidity Shock', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time (Days)', 'FontSize', 10);
ylabel('Cash Balance (Million USD)', 'FontSize', 10);
legend('PID Restored Cash Level', 'Target Cash Reserve', 'Location', 'lower right');
grid on;
% Аннотация времени стабилизации
text(6, target_cash*0.8, 'Settling Time \approx 5 Days', 'FontWeight', 'bold');
hold off;

% Сабплот 2: Управляющее воздействие (Control Effort)
subplot(1, 2, 2);
plot(t, u, 'k', 'LineWidth', 1.5); hold on;
% Закрашиваем область под графиком для наглядности
area(t, u, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none', 'ShowBaseLine', 'off');
plot(t, u, 'k', 'LineWidth', 1.5); % Возвращаем линию поверх заливки
plot(t, zeros(size(t)), 'r--', 'LineWidth', 1); % Нулевая линия

title('Control Effort: Capital Injection Requests', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time (Days)', 'FontSize', 10);
ylabel('Capital Requested / Absorbed (Million USD)', 'FontSize', 10);
legend('Credit Line / Asset Sales Demand', 'Location', 'upper right');
grid on; hold off;

disp('--- Execution Completed ---');
