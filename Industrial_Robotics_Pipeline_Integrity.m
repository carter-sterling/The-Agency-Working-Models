% ==========================================================
% CARTER & STERLING — QUANTITATIVE RESEARCH & ENGINEERING
% ==========================================================
% Project: Pipeline Integrity - PDE Heat Transfer & Robotics
% Author: Abzhamiev Bekdaulet, CEO
% Environment: GNU Octave
% ==========================================================

clear all; close all; clc;

disp('--- Carter & Sterling: Initializing Pipeline PDE & Robotics ---');

%% 1. PDE: Решение уравнения теплопроводности (Crank-Nicolson Method)
disp('1. Solving Heat Transfer PDE (Crank-Nicolson Scheme)...');
% Параметры трубы и материала (Сталь)
L = 0.05;               % Толщина стенки трубы (50 мм)
Nx = 50;                % Количество пространственных узлов
dx = L / (Nx - 1);      % Шаг по пространству
T_end = 120;            % Время симуляции (120 секунд)
Nt = 300;               % Количество шагов по времени
dt = T_end / (Nt - 1);  % Шаг по времени
alpha_steel = 1.2e-5;   % Коэффициент температуропроводности стали

% Коэффициент Фурье для схемы Кранка-Николсона
r = alpha_steel * dt / (2 * dx^2);

% Формирование тридиагональных матриц A (неявная) и B (явная часть)
% diag(v, k) создает матрицу со сдвигом k
main_A = (1 + 2*r) * ones(Nx-2, 1);
off_A  = -r * ones(Nx-3, 1);
A = diag(main_A) + diag(off_A, 1) + diag(off_A, -1);

main_B = (1 - 2*r) * ones(Nx-2, 1);
off_B  = r * ones(Nx-3, 1);
B = diag(main_B) + diag(off_B, 1) + diag(off_B, -1);

% Конвертируем в разреженные матрицы (Sparse) для ускорения прогонки
A = sparse(A);
B = sparse(B);

% Инициализация вектора температур
T_x = ones(Nx, 1) * 20; % Начальная температура трубы: 20 C
T_history = zeros(Nx, Nt);
T_history(:, 1) = T_x;

% Граничные условия (Boundary Conditions)
T_inner = 150; % Горячая нефть/газ внутри (150 C)
T_outer = 10;  % Внешняя среда (10 C)

% Цикл интегрирования по времени
for n = 2:Nt
    % Вектор правой части
    rhs = B * T_x(2:Nx-1);

    % Добавляем влияние граничных условий на края тридиагональной системы
    rhs(1) = rhs(1) + r * (T_inner + T_inner); % Левая граница
    rhs(end) = rhs(end) + r * (T_outer + T_outer); % Правая граница

    % Решение системы A * x = rhs (Алгоритм прогонки / Thomas Algorithm)
    T_x(2:Nx-1) = A \ rhs;

    % Обновляем границы
    T_x(1) = T_inner;
    T_x(end) = T_outer;

    % Сохраняем историю для тепловой карты
    T_history(:, n) = T_x;
end

%% 2. Робототехника: Прямая кинематика (Denavit-Hartenberg)
disp('2. Calculating Manipulator Kinematics (Denavit-Hartenberg)...');
% Робот имеет 3 степени свободы (3-DOF), стоит в центре трубы и сканирует стенку
num_points = 200;
theta1 = linspace(0, 4*pi, num_points); % Вращение базы (2 полных оборота)
d1 = linspace(0, 2, num_points);        % Движение вдоль трубы (Z-ось)
a2 = 0.4;                               % Длина первого звена (плечо)
a3 = 0.4;                               % Длина второго звена (инструмент сканирования)

% Массивы для хранения 3D координат
Base = zeros(3, num_points);
Joint1 = zeros(3, num_points);
EndEffector = zeros(3, num_points);

% Анонимная функция для генерации DH-матрицы трансформации
DH_Matrix = @(theta, d, a, alpha_angle) ...
    [cos(theta), -sin(theta)*cos(alpha_angle),  sin(theta)*sin(alpha_angle), a*cos(theta);
     sin(theta),  cos(theta)*cos(alpha_angle), -cos(theta)*sin(alpha_angle), a*sin(theta);
     0,           sin(alpha_angle),             cos(alpha_angle),            d;
     0,           0,                            0,                           1];

% Расчет траектории
for i = 1:num_points
    % Матрицы трансформации для каждого звена (Base -> Link1 -> EndEffector)
    T01 = DH_Matrix(theta1(i), d1(i), 0, pi/2);
    T12 = DH_Matrix(0, 0, a2, 0);
    T23 = DH_Matrix(0, 0, a3, 0);

    % Глобальные трансформации
    T02 = T01 * T12;
    T03 = T02 * T23; % Позиция рабочего инструмента

    % Извлекаем [x; y; z]
    Base(:, i) = T01(1:3, 4);
    Joint1(:, i) = T02(1:3, 4);
    EndEffector(:, i) = T03(1:3, 4);
end

%% 3. Визуализация (Executive Plots)
disp('3. Generating Institutional Graphics...');
figure('Position', [50, 100, 1200, 500]);

% Сабплот 1: Тепловая карта износа трубы (Heatmap PDE)
subplot(1, 2, 1);
imagesc(linspace(0, T_end, Nt), linspace(0, L*1000, Nx), T_history);
colormap('hot'); colorbar;
set(gca, 'YDir', 'normal');
title('Crank-Nicolson PDE: Pipeline Wall Heat Transfer', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time (seconds)', 'FontSize', 10);
ylabel('Wall Thickness (mm)', 'FontSize', 10);
% Аннотации
text(T_end*0.05, 5, 'Inner Flow (150 C)', 'Color', 'white', 'FontWeight', 'bold');
text(T_end*0.05, 45, 'Outer Environment (10 C)', 'Color', 'black', 'FontWeight', 'bold');

% Сабплот 2: 3D Кинематика робота
subplot(1, 2, 2);
hold on;
grid on; view(3);

% Рисуем стенки трубы (полупрозрачный цилиндр)
[Xc, Yc, Zc] = cylinder(0.8, 30);
Zc = Zc * 2; % Длина цилиндра
surf(Xc, Yc, Zc, 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'FaceColor', 'b');

% Рисуем траекторию сканирования (спираль)
plot3(EndEffector(1,:), EndEffector(2,:), EndEffector(3,:), 'r--', 'LineWidth', 1.5);

% Рисуем текущую (финальную) позицию манипулятора
plot3([Base(1,end), Joint1(1,end), EndEffector(1,end)], ...
      [Base(2,end), Joint1(2,end), EndEffector(2,end)], ...
      [Base(3,end), Joint1(3,end), EndEffector(3,end)], 'k-o', 'LineWidth', 3, 'MarkerSize', 8, 'MarkerFaceColor', 'y');

title('Denavit-Hartenberg 3D Kinematics: Diagnostic Scan', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (Pipeline Length, m)');
legend('Pipeline Boundary', 'Scanning Trajectory', 'Robotic Manipulator', 'Location', 'best');
axis equal; hold off;

disp('--- Execution Completed ---');
