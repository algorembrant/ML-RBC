% BeamAnalysis_Example4_1.m
% Analysis of Nominal Moment Strength (Mn) for Singly Reinforced Rectangular Section
% Based on Example 4-1 and 4-1M

clear; clc; close all;

%% 1. Input Variables (Adjustable)
% Toggle between Imperial (1) and SI (2) units
unit_system = 1; % 1 = Imperial (Example 4-1), 2 = SI (Example 4-1M)

if unit_system == 1
    % --- Imperial Units (Example 4-1) ---
    fprintf('Running Example 4-1 (Imperial Units)\n');
    fc_prime = 4000;    % Concrete compressive strength [psi]
    fy = 60000;         % Steel yield strength [psi]
    b = 12;             % Beam width [in]
    h = 20;             % Beam total depth [in]
    d = 17.5;           % Effective depth [in] (h - 2.5)
    
    % Reinforcement
    % 4 No. 8 bars: Area of one No. 8 is approx 0.79 in^2
    num_bars = 4;
    bar_area = 0.79;    % [in^2]
    As = num_bars * bar_area; % Total steel area [in^2]
    
    % Constants
    Es = 29000000;      % Modulus of Elasticity of Steel [psi]
    beta1 = 0.85;       % For fc' <= 4000 psi
    epsilon_cu = 0.003; % Ultimate concrete strain
    
    % Unit labels for plotting
    units = struct('len', 'in', 'force', 'lb', 'stress', 'psi', 'moment', 'k-in');
    
else
    % --- SI Units (Example 4-1M) ---
    fprintf('Running Example 4-1M (SI Units)\n');
    fc_prime = 20;      % [MPa] or [N/mm^2]
    fy = 420;           % [MPa]
    b = 250;            % [mm]
    h = 565;            % [mm]
    d = 500;            % [mm]
    
    % Reinforcement
    % 3 No. 25 bars: Area is approx 510 mm^2 each
    num_bars = 3;
    bar_area = 510;     % [mm^2]
    As = num_bars * bar_area; % [mm^2]
    
    % Constants
    Es = 200000;        % [MPa]
    beta1 = 0.85;
    epsilon_cu = 0.003;
    
    % Unit labels
    units = struct('len', 'mm', 'force', 'N', 'stress', 'MPa', 'moment', 'kN-m');
end

%% 2. Calculations (Step-by-Step)

% Step 1: Assume steel yields (fs = fy) and compute Tension Force (T)
T = As * fy;

% Step 2: Compute depth of equivalent rectangular stress block (a)
% Compression Force C = 0.85 * fc' * b * a
% Set C = T for equilibrium: 0.85 * fc' * b * a = As * fy
a = (As * fy) / (0.85 * fc_prime * b);

% Calculate neutral axis depth (c)
c = a / beta1;

% Step 3: Check that tension steel is yielding
% Strain in steel (epsilon_s) from similar triangles
epsilon_y = fy / Es;
epsilon_s = epsilon_cu * (d - c) / c;

fprintf('\n--- Calculation Results ---\n');
fprintf('Tension Force (T) = %.2f kips (or kN)\n', T/1000);
fprintf('Block depth (a)   = %.4f %s\n', a, units.len);
fprintf('Neutral axis (c)  = %.4f %s\n', c, units.len);
fprintf('Yield strain (eps_y) = %.5f\n', epsilon_y);
fprintf('Steel strain (eps_s) = %.5f\n', epsilon_s);

if epsilon_s >= epsilon_y
    fprintf('CHECK: Steel YIELDS (eps_s >= eps_y). Assumption OK.\n');
    fs = fy;
else
    fprintf('CHECK: Steel does NOT yield. Recalculation required (not implemented in this simple script).\n');
    fs = epsilon_s * Es;
end

% Step 4: Compute Nominal Moment Strength (Mn)
Mn = As * fs * (d - a/2);

if unit_system == 1
    Mn_kft = Mn / 12000; % Convert lb-in to k-ft
    fprintf('Nominal Moment (Mn) = %.0f %s\n', Mn, units.moment);
    fprintf('Nominal Moment (Mn) = %.1f k-ft\n', Mn_kft);
else
    Mn_kNm = Mn / 10^6; % Convert N-mm to kN-m
    fprintf('Nominal Moment (Mn) = %.0f N-mm\n', Mn);
    fprintf('Nominal Moment (Mn) = %.0f kN-m\n', Mn_kNm);
end

% Step 5: Check Minimum Steel Area (As,min)
if unit_system == 1
    % Imperial
    term1 = (3 * sqrt(fc_prime) / fy) * b * d;
    term2 = (200 / fy) * b * d;
    As_min = max(term1, term2);
else
    % SI
    term1 = (0.25 * sqrt(fc_prime) / fy) * b * d;
    term2 = (1.4 / fy) * b * d;
    As_min = max(term1, term2);
end

fprintf('Minimum Steel (As,min) = %.4f %s^2\n', As_min, units.len);
if As >= As_min
    fprintf('CHECK: As >= As_min. Requirement Satisfied.\n');
else
    fprintf('WARNING: As < As_min. Requirement NOT Satisfied.\n');
end

%% 3. Visualization

% --- VISUALIZATION OF EQUATIONS ---
% Create a dedicated area for equations (using annotations or a subplot)
% We'll adjust the subplot positions to leave room at the bottom or right.

% Clear current figure to resize/layout
clf;
set(gcf, 'Position', [100, 100, 1200, 800]); % Taller figure

% Define Layout
% Row 1: Diagrams (Section, Strain, Stress)
% Row 2: Calculation Sheet (Text)

% --- Subplot 1: Beam Cross Section ---
subplot(2, 3, 1);
hold on; axis equal;
title('Cross Section', 'FontSize', 12, 'FontWeight', 'bold');
% Draw concrete
rectangle('Position', [0, 0, b, h], 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'k', 'LineWidth', 1.5);
% Draw steel bars (simplified as circles)
bar_radius = sqrt(bar_area/pi); 
if num_bars == 1
    centers_x = b/2;
else
    centers_x = linspace(2.5, b-2.5, num_bars); % Just for viz, generic spacing
end
steel_y_loc = h - d; % Location of steel from bottom
for i = 1:num_bars
    pos = [centers_x(i)-bar_radius, steel_y_loc-bar_radius, 2*bar_radius, 2*bar_radius];
    rectangle('Position', pos, 'FaceColor', 'k', 'Curvature', [1 1]);
end
% Dimensions
plot([b+2, b+2], [0, h], 'k-'); text(b+3, h/2, sprintf('h=%.1f', h));
plot([b+2, b+2], [steel_y_loc, h], 'b-'); text(b+3, (h+steel_y_loc)/2, sprintf('d=%.1f', d));
plot([-2, -2], [h-a, h], 'r-', 'LineWidth', 2); text(-5, h-a/2, sprintf('a=%.2f', a), 'Color', 'r');
axis([-8 b+12 -5 h+5]);
xlabel(sprintf('b = %.1f %s', b, units.len));
set(gca, 'YTick', [], 'XTick', []);
box off; axis off;

% --- Subplot 2: Strain Diagram ---
subplot(2, 3, 2);
hold on;
title('Strain', 'FontSize', 12, 'FontWeight', 'bold');
% Compression top
plot([0, epsilon_cu*1000], [h, h], 'b-', 'LineWidth', 2); text(epsilon_cu*1000, h, sprintf('\\epsilon_{cu}=%.3f', epsilon_cu));
% Neutral axis
plot([0, 0], [0, h], 'k-');
plot([-1, 4], [h-c, h-c], 'k:'); text(-0.5, h-c, sprintf('c=%.2f', c), 'HorizontalAlignment', 'right');
% Steel strain
plot([0, epsilon_s*1000], [steel_y_loc, steel_y_loc], 'b-', 'LineWidth', 2); text(epsilon_s*1000, steel_y_loc, sprintf('\\epsilon_s=%.4f', epsilon_s));
% Connect lines
plot([epsilon_cu*1000, epsilon_s*1000], [h, steel_y_loc], 'r--');
plot([0, 0], [0, h], 'k-'); % Zero line
xlabel('Strain (x10^{-3})');
set(gca, 'YTick', [], 'XTick', []);
text(0, 0, ' '); % Spacer
axis([-2 8 -5 h+5]);
box off; axis off;

% --- Subplot 3: Stress/Force Diagram ---
subplot(2, 3, 3);
hold on;
title('Stresses & Forces', 'FontSize', 12, 'FontWeight', 'bold');
% Compression block
fill([0, 1, 1, 0], [h, h, h-a, h-a], 'r', 'FaceAlpha', 0.2);
plot([0.5, 0.5], [h, h-a], 'r-'); % Force line
quiver(1.2, h-a/2, -0.7, 0, 0, 'r', 'LineWidth', 2, 'MaxHeadSize', 0.5);
text(1.3, h-a/2, sprintf('C = 0.85f''_c b a\n= %.0f k', T/1000));

% Tension arrow
quiver(0, steel_y_loc, 1, 0, 0, 'b', 'LineWidth', 2, 'MaxHeadSize', 0.5);
text(1.1, steel_y_loc, sprintf('T = A_s f_y\n= %.0f k', T/1000));
% Neutral Axis
plot([0, 0], [0, h], 'k-');
plot([-0.5, 1.5], [h-c, h-c], 'k:');
xlabel('Stress');
axis([-0.5 2.5 -5 h+5]);
set(gca, 'YTick', [], 'XTick', []);
box off; axis off;

% --- Equation Panel (Bottom) ---
% We use a text box covering the lower half
axes('Position', [0, 0, 1, 0.45]);
axis off;

% Prepare Strings for Equations
% 1. Tension Force
eq1_sym = '$$T = A_s f_y$$';
eq1_sub = sprintf('$$= %.2f \\times %.0f = %.0f$$ lb (%.1f k)', As, fy, T, T/1000);

% 2. Compression Block depth
eq2_sym = '$$a = \frac{A_s f_y}{0.85 f''_c b}$$';
eq2_sub = sprintf('$$= \\frac{%.2f \\times %.0f}{0.85 \\times %.0f \\times %.1f} = %.4f$$ %s', As, fy, fc_prime, b, a, units.len);

% 3. Neutral Axis
eq3_sym = '$$c = \frac{a}{\beta_1}$$';
eq3_sub = sprintf('$$= \\frac{%.4f}{%.2f} = %.4f$$ %s', a, beta1, c, units.len);

% 4. Steel Strain
eq4_sym = '$$\epsilon_s = \frac{d-c}{c} \epsilon_{cu}$$';
eq4_sub = sprintf('$$= \\frac{%.1f - %.2f}{%.2f} (%.3f) = %.5f$$', d, c, c, epsilon_cu, epsilon_s);
if epsilon_s >= epsilon_y
    yield_msg = sprintf('($$\\ge \\epsilon_y = %.5f$$) OK', epsilon_y);
else
    yield_msg = sprintf('($$< \\epsilon_y = %.5f$$) NOT YIELDING', epsilon_y);
end

% 5. Nominal Moment
eq5_sym = '$$M_n = A_s f_y (d - \frac{a}{2})$$';
eq5_sub = sprintf('$$= %.2f \\times %.0f (%.1f - \\frac{%.2f}{2})$$', As, fy, d, a);
eq5_res = sprintf('$$= %.0f$$ %s = $$%.1f$$ %s', Mn, units.moment, Mn_kft, 'k-ft');

% Display Text
text_x = 0.05;
dy = 0.15;
current_y = 0.9;

text(text_x, current_y, '\underline{\textbf{CALCULATIONS}}', 'Interpreter', 'latex', 'FontSize', 14);
current_y = current_y - dy;

% T
text(text_x, current_y, [eq1_sym ' ' eq1_sub], 'Interpreter', 'latex', 'FontSize', 12);
current_y = current_y - dy;

% a
text(text_x, current_y, [eq2_sym ' ' eq2_sub], 'Interpreter', 'latex', 'FontSize', 12);
current_y = current_y - dy;

% c
text(text_x, current_y, [eq3_sym ' ' eq3_sub], 'Interpreter', 'latex', 'FontSize', 12);
text(text_x + 0.5, current_y, [eq4_sym ' ' eq4_sub ' ' yield_msg], 'Interpreter', 'latex', 'FontSize', 12);
current_y = current_y - dy;

% Mn
text(text_x, current_y, [eq5_sym ' ' eq5_sub ' ' eq5_res], 'Interpreter', 'latex', 'FontSize', 14, 'Color', 'b', 'FontWeight', 'bold');
current_y = current_y - dy;


sgtitle(sprintf('Example 4-1 Check: Mn = %.0f %s', Mn_kft, 'k-ft'));
