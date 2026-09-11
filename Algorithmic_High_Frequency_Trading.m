% ==========================================================
% CARTER & STERLING — QUANTITATIVE RESEARCH & ENGINEERING
% ==========================================================
% Project: HFT Spectral Filtering & Cycle Detection (FFT)
% Author: Abzhamiev Bekdaulet, CEO
% Environment: GNU Octave
% ==========================================================

clear all; close all; clc;

disp('--- Carter & Sterling: Initializing FFT Market Filter ---');

%% 1. Генерация высокочастотных синтетических данных (HFT Tick Data)
disp('1. Generating synthetic HFT tick data...');
Fs = 1000;            % Частота дискретизации (например, тиков в час)
T = 1/Fs;             % Период
L = 2000;             % Длина временного ряда
t = (0:L-1)*T;        % Вектор времени

% Моделируем "истинные" макро-циклы рынка (скрытые низкочастотные волны)
trend = 100 + 5 * t;           % Базовый восходящий тренд (DC offset)
cycle1 = 3 * sin(2*pi*5*t);    % Доминирующий цикл 1 (медленный, частота 5)
cycle2 = 1.5 * sin(2*pi*15*t); % Вторичный цикл 2 (быстрый, частота 15)

% Добавляем микроструктурный шум (Bid-Ask bounce, случайные сделки)
noise = 2 * randn(size(t));

% Итоговый "сырой" временной ряд (Raw Price)
raw_price = trend + cycle1 + cycle2 + noise;

%% 2. Применение Быстрого Преобразования Фурье (FFT)
disp('2. Computing Fast Fourier Transform (FFT)...');
Y = fft(raw_price);

% Расчет двустороннего и одностороннего спектра амплитуд для визуализации
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;

%% 3. Спектральная фильтрация (Удаление высокочастотного шума)
disp('3. Applying Amplitude Threshold Filter in Frequency Domain...');

% Устанавливаем порог отсечения (амплитуда ниже 0.5 считается белым шумом)
threshold = 0.5;

% Копируем исходный вектор Фурье
Y_filtered = Y;

% Обнуляем все частоты, которые не являются значимыми рыночными циклами
% Важно: нулевая частота (i=1) хранит базовый тренд, её обнулять нельзя
for i = 2:length(Y)
    if (abs(Y(i)/L) < threshold)
        Y_filtered(i) = 0;
    end
end

%% 4. Обратное преобразование Фурье (IFFT) для восстановления сигнала
disp('4. Reconstructing pure market signal via IFFT...');
% Восстанавливаем сигнал, избавляясь от мнимых погрешностей
clean_price = real(ifft(Y_filtered));

%% 5. Генерация торговых сигналов (Derivative-based Triggers)
disp('5. Generating Entry/Exit algorithmic trading signals...');
% Используем первую производную очищенного сигнала для поиска экстремумов
delta_price = diff(clean_price);

buy_signals = [];
sell_signals = [];

% Ищем моменты, когда производная пересекает ноль
for i = 2:length(delta_price)
    if delta_price(i-1) < 0 && delta_price(i) > 0
        buy_signals = [buy_signals, i]; % Локальный минимум (Дно -> Покупаем)
    elseif delta_price(i-1) > 0 && delta_price(i) < 0
        sell_signals = [sell_signals, i]; % Локальный максимум (Пик -> Продаем)
    end
end

%% 6. Визуализация результатов (Executive Charts)
disp('6. Plotting Spectral Analysis and Algorithmic Signals...');

figure('Position', [100, 100, 1000, 800]);

% Сабплот 1: Спектрограмма (Амплитудно-частотная характеристика)
subplot(2,1,1);
plot(f, P1, 'b', 'LineWidth', 1.5);
title('Carter & Sterling: Single-Sided Amplitude Spectrum of HFT Data', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Frequency (Market Cycle Speed)', 'FontSize', 10);
ylabel('|P1(f)| (Amplitude / Cycle Strength)', 'FontSize', 10);
xlim([0 30]); % Показываем только значимый диапазон низких частот
grid on;

% Сабплот 2: Сырые данные vs Очищенный сигнал + Сигналы
subplot(2,1,2);
% Сырой шум
plot(t, raw_price, 'Color', [0.7 0.7 0.7], 'LineWidth', 1); hold on;
% Очищенный тренд (без лага!)
plot(t, clean_price, 'k', 'LineWidth', 2);

% Отмечаем точки входа и выхода
plot(t(buy_signals), clean_price(buy_signals), 'g^', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
plot(t(sell_signals), clean_price(sell_signals), 'rv', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

title('Raw Tick Data vs. IFFT Cleaned Signal with Algorithmic Triggers', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time (t)', 'FontSize', 10);
ylabel('Asset Price', 'FontSize', 10);
legend('Raw HFT Data (Noisy)', 'FFT Cleaned Trend (Zero-lag)', 'Buy Signal (Trough)', 'Sell Signal (Peak)', 'Location', 'best');
grid on;
hold off;

disp('--- Execution Completed ---');
