# ML-RBC: Beam Analysis Tool

A MATLAB application for calculating the **Nominal Moment Strength (Mn)** of singly reinforced concrete beam sections, based on ACI 318 code provisions.

![MATLAB](https://img.shields.io/badge/MATLAB-R2020a%2B-orange)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## Features

- **Interactive GUI**: Real-time visualization as you adjust parameters
- **Dual Unit Support**: Switch between Imperial (psi, in) and SI (MPa, mm) units
- **Complete Variable Control**: Adjust all material and geometric properties
- **LaTeX Equations**: Step-by-step calculations displayed with mathematical notation
- **Visual Diagrams**: Cross-section, strain profile, and stress block illustrations

---

## Quick Start

### Requirements
- MATLAB R2020a or later (with App Designer support)

### Running the App
1. Clone or download this repository
2. Open MATLAB and navigate to the project folder
3. Run the app:
   ```matlab
   BeamAnalysisApp
   ```

---

## User Guide

### App Layout

| Panel | Description |
|-------|-------------|
| **Left Panel** | Input parameters (materials, geometry, reinforcement) |
| **Right Panel** | Visualizations (diagrams) and equation display |

### Input Parameters

#### Materials
| Parameter | Description | Imperial Default | SI Default |
|-----------|-------------|------------------|------------|
| fc' | Concrete compressive strength | 4000 psi | 20 MPa |
| fy | Steel yield strength | 60,000 psi | 420 MPa |
| Es | Modulus of elasticity of steel | 29×10⁶ psi | 200,000 MPa |
| β₁ | Stress block factor | 0.85 | 0.85 |
| εcu | Ultimate concrete strain | 0.003 | 0.003 |

#### Geometry
| Parameter | Description | Imperial Default | SI Default |
|-----------|-------------|------------------|------------|
| b | Beam width | 12 in | 250 mm |
| h | Total beam depth | 20 in | 565 mm |
| d | Effective depth | 17.5 in | 500 mm |

#### Reinforcement
| Parameter | Description | Imperial Default | SI Default |
|-----------|-------------|------------------|------------|
| Number of Bars | Count of tension bars | 4 | 3 |
| Bar Area | Area per bar | 0.79 in² | 510 mm² |

### How to Use

1. **Select Unit System**: Toggle the switch at the top between "Imperial" and "SI"
2. **Enter Values**: Modify any input field - the app updates automatically
3. **View Results**: 
   - **Diagrams**: See the beam section, strain distribution, and stress block
   - **Equations**: Follow the step-by-step calculations at the bottom
   - **Summary**: Check the results box for key values

### Calculation Steps (Based on Example 4-1)

The app follows the ACI 318 procedure:

1. **Calculate Total Steel Area**
   ```
   As = n × Abar
   ```

2. **Calculate Tension Force**
   ```
   T = As × fy
   ```

3. **Calculate Stress Block Depth**
   ```
   a = (As × fy) / (0.85 × fc' × b)
   ```

4. **Calculate Neutral Axis Depth**
   ```
   c = a / β₁
   ```

5. **Verify Steel Yielding** (Strain Compatibility)
   ```
   εy = fy / Es
   εs = ((d - c) / c) × εcu
   Check: εs ≥ εy
   ```

6. **Calculate Nominal Moment**
   ```
   Mn = As × fy × (d - a/2)
   ```

7. **Check Minimum Steel Area**
   ```
   As,min = max(3√fc'/fy × bw × d, 200/fy × bw × d)  [Imperial]
   As,min = max(0.25√fc'/fy × bw × d, 1.4/fy × bw × d)  [SI]
   ```

---

## Files

| File | Description |
|------|-------------|
| `BeamAnalysisApp.m` | Main interactive MATLAB App |
| `BeamAnalysis_Example4_1.m` | Static script version (for publication-quality figures) |
| `Example4-1/` | Reference images from textbook |

---

## Example Output

When running with default Imperial values (Example 4-1):
- **As** = 3.16 in²
- **T** = 190 kips
- **a** = 4.65 in
- **c** = 5.47 in
- **εs** = 0.00658 (> εy = 0.00207 ✓)
- **Mn** = 240 k-ft

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| App doesn't open | Ensure MATLAB R2020a+ with App Designer |
| Blank plots | Check that all input values are positive |
| LaTeX warnings (older MATLAB) | Some LaTeX features require R2021a+ |

---

## Theory Reference

This application implements the analysis procedure for singly reinforced rectangular beam sections as described in:

- **ACI 318-19**: Building Code Requirements for Structural Concrete
- **Section 4-4**: Analysis of Nominal Moment Strength for Singly Reinforced Beam Sections
- **Equations Referenced**: Eq. 4-11, 4-14a, 4-16, 4-18, 4-21

---

## License

MIT License - See LICENSE file for details.

---

## Citation

If you use this tool in your research or coursework, please cite:

```
@software{ML-RBC,
  author = {algorembrant},
  title = {ML-RBC: Beam Analysis Tool in MATLAB},
  year = {2026},
  url = {https://github.com/algorembrant/ML-RBC},
  note = {MATLAB application for nominal moment strength calculation of reinforced concrete beams}
}
```
