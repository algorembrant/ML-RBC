classdef BeamAnalysisApp < matlab.apps.AppBase
    % BeamAnalysisApp - Interactive Analysis of Nominal Moment Strength (Mn)
    % Based on Example 4-1 and 4-1M from ACI 318 Provisions
    %
    % Variables from Example:
    %   fc' - Concrete compressive strength
    %   fy  - Steel yield strength
    %   Es  - Modulus of elasticity of steel
    %   b   - Beam width
    %   h   - Total beam depth
    %   d   - Effective depth (to centroid of tension steel)
    %   As  - Total area of tension steel
    %   beta1 - Stress block factor (0.85 for fc' <= 4000 psi)
    %   epsilon_cu - Ultimate concrete strain (0.003)
    %
    % Calculated:
    %   T       - Tension force in steel
    %   a       - Depth of equivalent stress block
    %   c       - Neutral axis depth
    %   epsilon_y - Yield strain of steel
    %   epsilon_s - Strain in steel at ultimate
    %   Mn      - Nominal moment strength
    %   As_min  - Minimum steel area per ACI

    properties (Access = public)
        UIFigure      matlab.ui.Figure
        GridLayout    matlab.ui.container.GridLayout
        LeftPanel     matlab.ui.container.Panel
        RightPanel    matlab.ui.container.Panel
        
        % Inputs - Material
        UnitSwitch    matlab.ui.control.Switch
        EditFc        matlab.ui.control.NumericEditField
        EditFy        matlab.ui.control.NumericEditField
        EditEs        matlab.ui.control.NumericEditField
        EditBeta1     matlab.ui.control.NumericEditField
        EditEpsCu     matlab.ui.control.NumericEditField
        
        % Inputs - Geometry
        EditB         matlab.ui.control.NumericEditField
        EditH         matlab.ui.control.NumericEditField
        EditD         matlab.ui.control.NumericEditField
        
        % Inputs - Reinforcement
        EditBars      matlab.ui.control.NumericEditField
        EditBarArea   matlab.ui.control.NumericEditField
        
        % Visualization Axes
        AxSection     matlab.ui.control.UIAxes
        AxStrain      matlab.ui.control.UIAxes
        AxStress      matlab.ui.control.UIAxes
        AxEquations   matlab.ui.control.UIAxes  % For LaTeX rendering
        
        % Results Panel
        ResultLabel   matlab.ui.control.Label
    end

    properties (Access = private)
        Units struct
    end

    methods (Access = private)

        function updateApp(app, ~)
            % === 1. GET INPUTS ===
            is_imperial = strcmp(app.UnitSwitch.Value, 'Imperial');
            
            fc = app.EditFc.Value;
            fy = app.EditFy.Value;
            Es = app.EditEs.Value;
            beta1 = app.EditBeta1.Value;
            epsilon_cu = app.EditEpsCu.Value;
            b  = app.EditB.Value;
            h  = app.EditH.Value;
            d  = app.EditD.Value;
            n_bars = app.EditBars.Value;
            bar_A  = app.EditBarArea.Value;
            As = n_bars * bar_A;

            % Set units
            if is_imperial
                app.Units = struct('len', 'in', 'area', 'in^2', 'force', 'lb', ...
                    'stress', 'psi', 'moment', 'lb-in', 'moment_k', 'k-in', 'moment_alt', 'k-ft');
            else
                app.Units = struct('len', 'mm', 'area', 'mm^2', 'force', 'N', ...
                    'stress', 'MPa', 'moment', 'N-mm', 'moment_k', 'N-mm', 'moment_alt', 'kN-m');
            end
            u = app.Units;

            % === 2. CALCULATIONS (Following Example 4-1 Steps) ===
            
            % STEP 1: Compute Steel Tension Force T
            % Assumption: Steel yields (fs = fy)
            T = As * fy;
            
            % STEP 2: Compute depth of equivalent stress block (a)
            % From equilibrium: C = T  =>  0.85 * fc' * b * a = As * fy
            a = (As * fy) / (0.85 * fc * b);
            
            % Neutral axis depth c = a / beta1
            c = a / beta1;
            
            % STEP 3: Check if tension steel is yielding
            epsilon_y = fy / Es;  % Yield strain
            epsilon_s = epsilon_cu * (d - c) / c;  % Strain compatibility (Eq. 4-18)
            
            if epsilon_s >= epsilon_y
                yield_check = true;
                fs = fy;
            else
                yield_check = false;
                fs = epsilon_s * Es;
            end
            
            % STEP 4: Compute Nominal Moment Strength Mn (Eq. 4-21)
            Mn = As * fs * (d - a/2);
            
            % Convert Mn for display
            if is_imperial
                Mn_disp = Mn / 12000; % k-ft
                T_disp = T / 1000;    % kips
                Mn_k = Mn / 1000;     % k-in
            else
                Mn_disp = Mn / 1e6;   % kN-m
                T_disp = T / 1000;    % kN
                Mn_k = Mn;            % N-mm
            end

            % STEP 5: Check Minimum Steel Area As,min (Eq. 4-11)
            if is_imperial
                term1 = (3 * sqrt(fc) / fy) * b * d;
                term2 = (200 / fy) * b * d;
            else
                term1 = (0.25 * sqrt(fc) / fy) * b * d;
                term2 = (1.4 / fy) * b * d;
            end
            As_min = max(term1, term2);
            As_check = As >= As_min;
            
            % === 3. VISUALIZATION ===
            
            % --- Section Plot ---
            ax = app.AxSection;
            cla(ax); hold(ax, 'on'); 
            axis(ax, 'equal');
            title(ax, 'Cross Section', 'FontWeight', 'bold');
            
            % Concrete outline
            rectangle(ax, 'Position', [0, 0, b, h], 'FaceColor', [0.85 0.85 0.85], 'EdgeColor', 'k', 'LineWidth', 1.5);
            
            % Compression zone shading
            fill(ax, [0, b, b, 0], [h, h, h-a, h-a], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
            
            % Steel bars
            bar_r = sqrt(bar_A/pi) * 0.8;
            steel_y = h - d;
            if n_bars == 1
                cx = b/2;
            else
                cx = linspace(b*0.15, b*0.85, n_bars);
            end
            for i=1:n_bars
                rectangle(ax, 'Position', [cx(i)-bar_r, steel_y-bar_r, 2*bar_r, 2*bar_r], ...
                    'FaceColor', [0.2 0.2 0.2], 'EdgeColor', 'k', 'Curvature', [1 1]);
            end
            
            % Dimension lines and labels
            % h (total depth)
            plot(ax, [b+b*0.1, b+b*0.1], [0, h], 'k-', 'LineWidth', 1);
            plot(ax, [b, b+b*0.15], [0, 0], 'k-');
            plot(ax, [b, b+b*0.15], [h, h], 'k-');
            text(ax, b+b*0.15, h/2, sprintf('h = %.1f %s', h, u.len), 'FontSize', 9);
            
            % d (effective depth)
            plot(ax, [b+b*0.3, b+b*0.3], [steel_y, h], 'b-', 'LineWidth', 1);
            text(ax, b+b*0.35, (h+steel_y)/2, sprintf('d = %.1f %s', d, u.len), 'Color', 'b', 'FontSize', 9);
            
            % a (stress block)
            plot(ax, [-b*0.1, -b*0.1], [h-a, h], 'r-', 'LineWidth', 2);
            text(ax, -b*0.4, h-a/2, sprintf('a = %.2f %s', a, u.len), 'Color', 'r', 'FontSize', 9);
            
            % c (neutral axis)
            plot(ax, [0, b], [h-c, h-c], 'k--', 'LineWidth', 1);
            text(ax, b*0.5, h-c+h*0.03, sprintf('c = %.2f', c), 'HorizontalAlignment', 'center', 'FontSize', 8);
            
            % b (width)
            text(ax, b/2, -h*0.08, sprintf('b = %.1f %s', b, u.len), 'HorizontalAlignment', 'center', 'FontSize', 9);
            
            ax.XLim = [-b*0.5, b*1.6];
            ax.YLim = [-h*0.15, h*1.1];
            ax.XTick = []; ax.YTick = [];
            box(ax, 'off');
            
            % --- Strain Diagram ---
            ax = app.AxStrain;
            cla(ax); hold(ax, 'on');
            title(ax, 'Strain Profile', 'FontWeight', 'bold');
            
            % Scale factor for visualization
            x_scale = b * 0.4 / epsilon_cu;
            
            % Strain profile
            fill(ax, [0, epsilon_cu*x_scale, epsilon_s*x_scale, 0], [h, h, steel_y, steel_y], ...
                [0.8 0.9 1], 'EdgeColor', 'b', 'LineWidth', 1.5);
            
            % Neutral axis
            plot(ax, [0, 0], [0, h], 'k-', 'LineWidth', 1);
            plot(ax, [-b*0.1, b*0.6], [h-c, h-c], 'k:', 'LineWidth', 1);
            text(ax, -b*0.05, h-c, 'N.A.', 'FontSize', 8, 'HorizontalAlignment', 'right');
            
            % Labels
            text(ax, epsilon_cu*x_scale, h+h*0.03, sprintf('\\epsilon_{cu} = %.4f', epsilon_cu), 'FontSize', 9, 'Color', 'b');
            text(ax, epsilon_s*x_scale, steel_y-h*0.03, sprintf('\\epsilon_s = %.5f', epsilon_s), 'FontSize', 9, 'Color', 'b');
            text(ax, 0, h-c/2, sprintf('c=%.2f', c), 'FontSize', 8);
            
            ax.XLim = [-b*0.15, b*0.8];
            ax.YLim = [-h*0.1, h*1.15];
            ax.XTick = []; ax.YTick = [];
            box(ax, 'off');
            
            % --- Stress/Force Diagram ---
            ax = app.AxStress;
            cla(ax); hold(ax, 'on');
            title(ax, 'Stresses & Forces', 'FontWeight', 'bold');
            
            x_scale = b * 0.6;
            
            % Compression block (0.85 fc')
            fill(ax, [0, x_scale, x_scale, 0], [h, h, h-a, h-a], [1 0.7 0.7], 'EdgeColor', 'r', 'LineWidth', 1.5);
            text(ax, x_scale/2, h-a/2, sprintf('0.85 f''_c'), 'HorizontalAlignment', 'center', 'FontSize', 9);
            
            % Compression force C
            quiver(ax, x_scale*1.1, h-a/2, x_scale*0.4, 0, 0, 'r', 'LineWidth', 2, 'MaxHeadSize', 0.8);
            text(ax, x_scale*1.6, h-a/2, sprintf('C = %.0f k', T_disp), 'Color', 'r', 'FontSize', 9);
            
            % Tension force T
            quiver(ax, -x_scale*0.1, steel_y, x_scale*0.5, 0, 0, 'b', 'LineWidth', 2, 'MaxHeadSize', 0.8);
            text(ax, x_scale*0.5, steel_y, sprintf('T = %.0f k', T_disp), 'Color', 'b', 'FontSize', 9);
            
            % Moment arm
            plot(ax, [x_scale*1.8, x_scale*1.8], [h-a/2, steel_y], 'g-', 'LineWidth', 1.5);
            text(ax, x_scale*1.9, (h-a/2+steel_y)/2, sprintf('d - a/2'), 'Color', [0 0.5 0], 'FontSize', 9);
            
            % Neutral axis
            plot(ax, [-b*0.2, b*1.5], [h-c, h-c], 'k:', 'LineWidth', 1);
            
            ax.XLim = [-b*0.3, b*2.2];
            ax.YLim = [-h*0.1, h*1.1];
            ax.XTick = []; ax.YTick = [];
            box(ax, 'off');
            
            % --- Equations Panel (LaTeX in UIAxes) ---
            ax = app.AxEquations;
            cla(ax); hold(ax, 'on');
            axis(ax, 'off');
            ax.XLim = [0 1]; ax.YLim = [0 1];
            
            y = 0.95; dy = 0.14;
            fs_size = 11;
            
            % Title
            text(ax, 0.02, y, '\bf{CALCULATIONS (Example 4-1 Procedure)}', 'Interpreter', 'tex', 'FontSize', 12);
            y = y - dy*0.8;
            
            % Step 1: As and T
            eq1 = sprintf('$$A_s = n \\times A_{bar} = %.0f \\times %.2f = %.2f \\; \\mathrm{%s}$$', n_bars, bar_A, As, u.area);
            text(ax, 0.02, y, eq1, 'Interpreter', 'latex', 'FontSize', fs_size);
            y = y - dy*0.7;
            
            eq2 = sprintf('$$T = A_s f_y = %.2f \\times %.0f = %.0f \\; \\mathrm{%s} \\; (%.1f \\; \\mathrm{k})$$', As, fy, T, u.force, T_disp);
            text(ax, 0.02, y, eq2, 'Interpreter', 'latex', 'FontSize', fs_size);
            y = y - dy;
            
            % Step 2: a and c
            eq3 = sprintf('$$a = \\frac{A_s f_y}{0.85 f''_c b} = \\frac{%.0f}{0.85 \\times %.0f \\times %.1f} = %.4f \\; \\mathrm{%s}$$', T, fc, b, a, u.len);
            text(ax, 0.02, y, eq3, 'Interpreter', 'latex', 'FontSize', fs_size);
            y = y - dy*0.7;
            
            eq4 = sprintf('$$c = \\frac{a}{\\beta_1} = \\frac{%.4f}{%.2f} = %.4f \\; \\mathrm{%s}$$', a, beta1, c, u.len);
            text(ax, 0.02, y, eq4, 'Interpreter', 'latex', 'FontSize', fs_size);
            y = y - dy;
            
            % Step 3: Strain check
            eq5 = sprintf('$$\\varepsilon_y = \\frac{f_y}{E_s} = \\frac{%.0f}{%.0f} = %.5f$$', fy, Es, epsilon_y);
            text(ax, 0.02, y, eq5, 'Interpreter', 'latex', 'FontSize', fs_size);
            y = y - dy*0.7;
            
            eq6 = sprintf('$$\\varepsilon_s = \\left(\\frac{d - c}{c}\\right) \\varepsilon_{cu} = \\left(\\frac{%.2f - %.2f}{%.2f}\\right)(%.4f) = %.5f$$', d, c, c, epsilon_cu, epsilon_s);
            text(ax, 0.02, y, eq6, 'Interpreter', 'latex', 'FontSize', fs_size);
            
            % Check result
            if yield_check
                chk_txt = '(OK: Steel Yields)';
                chk_color = [0 0.5 0];
            else
                chk_txt = '(NOT OK: Steel Not Yielding)';
                chk_color = [0.8 0 0];
            end
            text(ax, 0.55, y, chk_txt, 'Interpreter', 'none', 'FontSize', fs_size, 'Color', chk_color, 'FontWeight', 'bold');
            y = y - dy;
            
            % Step 4: Mn
            eq7 = sprintf('$$M_n = A_s f_y \\left( d - \\frac{a}{2} \\right) = %.0f \\left( %.2f - \\frac{%.4f}{2} \\right)$$', T, d, a);
            text(ax, 0.02, y, eq7, 'Interpreter', 'latex', 'FontSize', fs_size);
            y = y - dy*0.7;
            
            eq8 = sprintf('M_n = %.0f %s = %.1f %s', Mn_k, u.moment_k, Mn_disp, u.moment_alt);
            text(ax, 0.02, y, eq8, 'Interpreter', 'none', 'FontSize', 14, 'Color', 'b', 'FontWeight', 'bold');
            y = y - dy;
            
            % Step 5: As_min
            if is_imperial
                eq9 = sprintf('$$A_{s,min} = \\max\\left( \\frac{3\\sqrt{f''_c}}{f_y} b_w d, \\; \\frac{200}{f_y} b_w d \\right) = %.4f \\; \\mathrm{%s}$$', As_min, u.area);
            else
                eq9 = sprintf('$$A_{s,min} = \\max\\left( \\frac{0.25\\sqrt{f''_c}}{f_y} b_w d, \\; \\frac{1.4}{f_y} b_w d \\right) = %.1f \\; \\mathrm{%s}$$', As_min, u.area);
            end
            text(ax, 0.02, y, eq9, 'Interpreter', 'latex', 'FontSize', fs_size);
            
            if As_check
                chk2_txt = '(OK)';
                chk2_color = [0 0.5 0];
            else
                chk2_txt = '(NOT OK)';
                chk2_color = [0.8 0 0];
            end
            text(ax, 0.7, y, chk2_txt, 'Interpreter', 'none', 'FontSize', fs_size, 'Color', chk2_color, 'FontWeight', 'bold');
            
            % === 4. UPDATE RESULTS LABEL ===
            app.ResultLabel.Text = sprintf([...
                'RESULTS SUMMARY\n' ...
                '─────────────────\n' ...
                'As = %.2f %s\n' ...
                'T = C = %.1f kips\n' ...
                'a = %.4f %s\n' ...
                'c = %.4f %s\n' ...
                'εy = %.5f\n' ...
                'εs = %.5f\n' ...
                '─────────────────\n' ...
                'Mn = %.1f %s\n' ...
                'As,min = %.4f %s\n'], ...
                As, u.area, T_disp, a, u.len, c, u.len, epsilon_y, epsilon_s, Mn_disp, u.moment_alt, As_min, u.area);
        end
        
        function switchUnits(app, ~)
            if strcmp(app.UnitSwitch.Value, 'Imperial')
                % Example 4-1 defaults
                app.EditFc.Value = 4000;
                app.EditFy.Value = 60000;
                app.EditEs.Value = 29000000;
                app.EditBeta1.Value = 0.85;
                app.EditEpsCu.Value = 0.003;
                app.EditB.Value = 12;
                app.EditH.Value = 20;
                app.EditD.Value = 17.5;
                app.EditBars.Value = 4;
                app.EditBarArea.Value = 0.79;
            else
                % Example 4-1M defaults
                app.EditFc.Value = 20;
                app.EditFy.Value = 420;
                app.EditEs.Value = 200000;
                app.EditBeta1.Value = 0.85;
                app.EditEpsCu.Value = 0.003;
                app.EditB.Value = 250;
                app.EditH.Value = 565;
                app.EditD.Value = 500;
                app.EditBars.Value = 3;
                app.EditBarArea.Value = 510;
            end
            updateApp(app);
        end
    end

    methods (Access = public)
        function app = BeamAnalysisApp()
            createComponents(app);
            updateApp(app);
            registerApp(app, app.UIFigure);
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure);
        end
    end
    
    methods (Access = private)
        function createComponents(app)
            % === MAIN FIGURE ===
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [50 50 1300 750];
            app.UIFigure.Name = 'Beam Analysis - Example 4-1';
            app.UIFigure.Color = [0.98 0.98 0.98];

            % === MAIN GRID ===
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'0.22x', '0.78x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.Padding = [5 5 5 5];

            % === LEFT PANEL (Inputs) ===
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            app.LeftPanel.Title = 'INPUT PARAMETERS';
            app.LeftPanel.FontWeight = 'bold';
            app.LeftPanel.Scrollable = 'on';

            inpGrid = uigridlayout(app.LeftPanel);
            inpGrid.ColumnWidth = {'1.2x', '1x'};
            inpGrid.RowHeight = repmat({'fit'}, 1, 14);
            inpGrid.RowSpacing = 5;
            
            % --- Row 1: Units ---
            lbl = uilabel(inpGrid); lbl.Text = 'Unit System'; lbl.FontWeight = 'bold';
            app.UnitSwitch = uiswitch(inpGrid, 'slider');
            app.UnitSwitch.Items = {'Imperial', 'SI'};
            app.UnitSwitch.ValueChangedFcn = createCallbackFcn(app, @switchUnits, true);
            
            % --- Separator ---
            lbl = uilabel(inpGrid); lbl.Text = '── Materials ──'; lbl.FontAngle = 'italic';
            uilabel(inpGrid);
            
            % --- fc ---
            lbl = uilabel(inpGrid); lbl.Text = 'fc'' (Concrete)';
            app.EditFc = uieditfield(inpGrid, 'numeric');
            app.EditFc.ValueChangedFcn = createCallbackFcn(app, @updateApp, true);
            
            % --- fy ---
            lbl = uilabel(inpGrid); lbl.Text = 'fy (Steel Yield)';
            app.EditFy = uieditfield(inpGrid, 'numeric');
            app.EditFy.ValueChangedFcn = createCallbackFcn(app, @updateApp, true);
            
            % --- Es ---
            lbl = uilabel(inpGrid); lbl.Text = 'Es (Steel Modulus)';
            app.EditEs = uieditfield(inpGrid, 'numeric');
            app.EditEs.ValueChangedFcn = createCallbackFcn(app, @updateApp, true);
            
            % --- beta1 ---
            lbl = uilabel(inpGrid); lbl.Text = 'β₁ (Stress Block)';
            app.EditBeta1 = uieditfield(inpGrid, 'numeric');
            app.EditBeta1.ValueChangedFcn = createCallbackFcn(app, @updateApp, true);
            
            % --- epsilon_cu ---
            lbl = uilabel(inpGrid); lbl.Text = 'εcu (Ult. Strain)';
            app.EditEpsCu = uieditfield(inpGrid, 'numeric');
            app.EditEpsCu.ValueDisplayFormat = '%.4f';
            app.EditEpsCu.ValueChangedFcn = createCallbackFcn(app, @updateApp, true);
            
            % --- Separator ---
            lbl = uilabel(inpGrid); lbl.Text = '── Geometry ──'; lbl.FontAngle = 'italic';
            uilabel(inpGrid);
            
            % --- b ---
            lbl = uilabel(inpGrid); lbl.Text = 'b (Width)';
            app.EditB = uieditfield(inpGrid, 'numeric');
            app.EditB.ValueChangedFcn = createCallbackFcn(app, @updateApp, true);
            
            % --- h ---
            lbl = uilabel(inpGrid); lbl.Text = 'h (Total Depth)';
            app.EditH = uieditfield(inpGrid, 'numeric');
            app.EditH.ValueChangedFcn = createCallbackFcn(app, @updateApp, true);
            
            % --- d ---
            lbl = uilabel(inpGrid); lbl.Text = 'd (Eff. Depth)';
            app.EditD = uieditfield(inpGrid, 'numeric');
            app.EditD.ValueChangedFcn = createCallbackFcn(app, @updateApp, true);
            
            % --- Separator ---
            lbl = uilabel(inpGrid); lbl.Text = '── Reinforcement ──'; lbl.FontAngle = 'italic';
            uilabel(inpGrid);
            
            % --- Bars ---
            lbl = uilabel(inpGrid); lbl.Text = 'Number of Bars';
            app.EditBars = uieditfield(inpGrid, 'numeric');
            app.EditBars.ValueDisplayFormat = '%.0f';
            app.EditBars.ValueChangedFcn = createCallbackFcn(app, @updateApp, true);
            
            % --- Bar Area ---
            lbl = uilabel(inpGrid); lbl.Text = 'Bar Area (each)';
            app.EditBarArea = uieditfield(inpGrid, 'numeric');
            app.EditBarArea.ValueChangedFcn = createCallbackFcn(app, @updateApp, true);

            % === RIGHT PANEL (Visualization) ===
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;
            app.RightPanel.Title = 'VISUALIZATION & EQUATIONS';
            app.RightPanel.FontWeight = 'bold';
            
            rGrid = uigridlayout(app.RightPanel);
            rGrid.ColumnWidth = {'1x', '1x', '1x', '0.8x'};
            rGrid.RowHeight = {'1.5x', '2x'};
            rGrid.Padding = [5 5 5 5];
            
            % --- Row 1: Diagrams ---
            app.AxSection = uiaxes(rGrid);
            app.AxSection.Layout.Row = 1;
            app.AxSection.Layout.Column = 1;
            
            app.AxStrain = uiaxes(rGrid);
            app.AxStrain.Layout.Row = 1;
            app.AxStrain.Layout.Column = 2;
            
            app.AxStress = uiaxes(rGrid);
            app.AxStress.Layout.Row = 1;
            app.AxStress.Layout.Column = 3;
            
            % Results Summary
            app.ResultLabel = uilabel(rGrid);
            app.ResultLabel.Layout.Row = 1;
            app.ResultLabel.Layout.Column = 4;
            app.ResultLabel.VerticalAlignment = 'top';
            app.ResultLabel.Text = 'Results...';
            app.ResultLabel.FontName = 'Consolas';
            app.ResultLabel.FontSize = 11;
            app.ResultLabel.BackgroundColor = [1 1 0.9];
            
            % --- Row 2: Equations ---
            app.AxEquations = uiaxes(rGrid);
            app.AxEquations.Layout.Row = 2;
            app.AxEquations.Layout.Column = [1 4];
            app.AxEquations.XTick = [];
            app.AxEquations.YTick = [];
            app.AxEquations.Box = 'on';
            app.AxEquations.Color = [1 1 1];

            % === SET INITIAL VALUES (Imperial) ===
            app.EditFc.Value = 4000;
            app.EditFy.Value = 60000;
            app.EditEs.Value = 29000000;
            app.EditBeta1.Value = 0.85;
            app.EditEpsCu.Value = 0.003;
            app.EditB.Value = 12;
            app.EditH.Value = 20;
            app.EditD.Value = 17.5;
            app.EditBars.Value = 4;
            app.EditBarArea.Value = 0.79;

            app.UIFigure.Visible = 'on';
        end
    end
end
