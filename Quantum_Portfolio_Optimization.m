% ==========================================================
% CARTER & STERLING — QUANTITATIVE RESEARCH & ENGINEERING
% ==========================================================
% Project: Quantum Portfolio Optimization (Sparse QP)
% Author: Abzhamiev Bekdaulet, CEO
% Environment: GNU Octave
% ==========================================================

clear all; close all; clc;

disp('--- Carter & Sterling: Initializing Portfolio Optimization ---');

%% 1. Генерация синтетических данных высокой размерности
% Симулируем 200 активов и 1000 торговых дней
N = 200;       % Количество активов
T = 1000;      % Временной горизонт (дни)
Rf = 0.02;     % Безрисковая ставка (2% годовых)

disp('1. Generating synthetic market data...');
% Случайные ожидаемые доходности (от 2% до 15% годовых)
mu_annual = 0.02 + 0.13 * rand(N, 1);
mu_daily = mu_annual / 252;

% Генерация случайных временных рядов (геометрическое броуновское движение)
% Создаем коррелированный рыночный шум
market_factor = randn(T, 1) * 0.01;
asset_returns = repmat(mu_daily', T, 1) + 0.015 * randn(T, N) + 0.5 * market_factor;

%% 2. Расчет разреженной матрицы ковариации (Sparse Covariance)
disp('2. Estimating Sparse Covariance Matrix...');
Sigma = cov(asset_returns) * 252; % Аннуализированная ковариация

% Применяем "жесткое пороговое отсечение" (Hard Thresholding),
% чтобы сделать матрицу разреженной (убираем рыночный шум между не связанными активами)
threshold = 0.005;
Sigma(abs(Sigma) < threshold) = 0;

% Добавляем регуляризацию Тихонова (Ridge) для обеспечения положительной определенности
Sigma = Sigma + eye(N) * 1e-4;

% Конвертируем в тип sparse для ускорения вычислений
H = sparse(Sigma);

%% 3. Настройка параметров Квадратичного Программирования (Quadratic Programming)
% Решаем: min (1/2)*w'*H*w + q'*w
% при условиях: A*w = b (сумма весов = 1), lb <= w <= ub (веса >= 0)

A = ones(1, N);       % Ограничение на сумму весов
b = 1;                % Сумма весов = 100%
lb = zeros(N, 1);     % Запрет коротких позиций (Short Selling)
ub = ones(N, 1);      % Максимум 100% в один актив
x0 = ones(N, 1) / N;  % Начальная точка (равновзвешенный портфель)

% Вектор толерантности к риску (lambda)
lambdas = logspace(-1, 3, 50);
port_returns = zeros(length(lambdas), 1);
port_risks = zeros(length(lambdas), 1);
port_weights = zeros(N, length(lambdas));

%% 4. Векторный расчет Границы Эффективности (Efficient Frontier)
disp('3. Solving KKT conditions via qp() for Efficient Frontier...');
for i = 1:length(lambdas)
    lambda_val = lambdas(i);

    % Вектор q = -lambda * mu (минимизируем риск, максимизируем доходность)
    q = -lambda_val * mu_annual;

    % Решение через встроенный QP-солвер Octave
    % Синтаксис: qp (x0, H, q, A, b, lb, ub)
    [w_opt, obj, info] = qp(x0, H, q, A, b, lb, ub);

    % Сохраняем результаты
    port_weights(:, i) = w_opt;
    port_returns(i) = mu_annual' * w_opt;
    port_risks(i) = sqrt(w_opt' * H * w_opt);
end

%% 5. Поиск Tangency Portfolio (Максимальный коэффициент Шарпа)
disp('4. Calculating Maximum Sharpe Ratio...');
sharpe_ratios = (port_returns - Rf) ./ port_risks;
[max_sharpe, max_idx] = max(sharpe_ratios);

opt_return = port_returns(max_idx);
opt_risk = port_risks(max_idx);
opt_w = port_weights(:, max_idx);

fprintf('=== OPTIMIZATION RESULTS ===\n');
fprintf('Tangency Portfolio Expected Return: %.2f%%\n', opt_return * 100);
fprintf('Tangency Portfolio Volatility: %.2f%%\n', opt_risk * 100);
fprintf('Maximum Sharpe Ratio: %.2f\n', max_sharpe);
fprintf('Number of active assets in portfolio: %d out of %d\n', sum(opt_w > 0.01), N);

%% 6. Визуализация (Plotting)
disp('5. Generating Executive Charts...');
figure('Position', [100, 100, 800, 600]);

% Плотим все активы как серые точки
plot(sqrt(diag(H)), mu_annual, '.', 'Color', [0.7 0.7 0.7], 'MarkerSize', 10);
hold on;

% Плотим Efficient Frontier
plot(port_risks, port_returns, 'k-', 'LineWidth', 2);

% Отмечаем Tangency Portfolio
plot(opt_risk, opt_return, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');

% Оформление по стандартам
title('Carter & Sterling: Markowitz Efficient Frontier (Sparse QP)', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Annualized Risk (Volatility)', 'FontSize', 12);
ylabel('Annualized Expected Return', 'FontSize', 12);
grid on;
legend('Individual Assets', 'Efficient Frontier', 'Max Sharpe (Tangency) Portfolio', 'Location', 'best');

% Рисуем Capital Market Line (CML)
cml_risks = linspace(0, max(port_risks), 100);
cml_returns = Rf + max_sharpe * cml_risks;
plot(cml_risks, cml_returns, 'b--', 'LineWidth', 1.5);
legend('Individual Assets', 'Efficient Frontier', 'Max Sharpe Portfolio', 'Capital Market Line');

hold off;
disp('--- Execution Completed ---');
