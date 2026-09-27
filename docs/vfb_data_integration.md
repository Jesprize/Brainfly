# Virtual Fly Brain (VFB) Data Integration

## 1. Dataset/Source
**Source:** Virtual Fly Brain (VFB) / FlyCircuit / Janelia Hemibrain
**Target Organism:** Adult *Drosophila melanogaster*
**Reference Brain:** JRC2018 (or FCWB - FlyCircuit Whole Brain)

## 2. File Types & Scientific Meaning
- **SWC (Stockholm-Waterloo-Cali format):** 
  - *Scientific Meaning:* Represents the 3D morphology of individual neurons. It is a text-based format where each line represents a node in the neuron's tree structure (soma, axon, dendrite), containing 3D spatial coordinates (X, Y, Z), radius, and parent linkage.
  - *Usage:* Lightweight. We can parse this in Flutter to visualize accurate biological neuron shapes in the Scientist Observatory.
- **OBJ (Wavefront 3D Object):** 
  - *Scientific Meaning:* Represents the 3D surface mesh of brain structures (e.g., the whole brain boundary, optic lobes, mushroom bodies).
  - *Usage:* Usable. Can be loaded in Flutter (via custom parser or 3D package) to provide an anatomical backdrop for the biological neural layer.
- **NRRD (Nearly Raw Raster Data):** 
  - *Scientific Meaning:* Dense 3D volumetric raster/voxel data, typically representing confocal microscopy stacks or neuropil density.
  - *Usage:* Extremely heavy (often >50MB). Unsuitable for direct runtime rendering on mobile. Requires offline preprocessing into meshes (OBJ) or simplified density maps.

## 3. License/Attribution
Data downloaded from VFB is subject to CC BY 4.0 or CC0 depending on the specific laboratory (e.g., Janelia Research Campus, FlyCircuit). We must include attribution in `assets/brain/vfb/metadata/ATTRIBUTION.txt`.

## 4. Proposed BrainFly Integration
**Goal:** Introduce a Biological Brain Layer (`lib/artificial_life/biology/brain/`) strictly for structural reference and scientific visualization in the UI, decoupled from the core ALife learning engine.

**Strict Architecture Constraints:**
- The VFB data will **NOT** be used to create semantic behavioral rules (e.g., "if food, activate neuron X").
- The biological layer will act as a *spatial and anatomical mapping* substrate. The actual learning and behavior still emerge from the `ALifeNetwork`.
- The Scientist Observatory will parse and render the SWC and OBJ files to visualize the underlying biological layout corresponding to the organism.

## 5. Preprocessing Requirements
- **OBJ files:** Downsample if the vertex count exceeds 10,000 to ensure smooth 60fps rendering in Flutter.
- **SWC files:** Directly parsable in Dart using a custom string tokenizer. No heavy preprocessing required unless aggregating millions of neurons.
- **NRRD files:** Ignored for this phase due to memory constraints.

## 6. Phase 1 Implementation Plan
1. Download a representative sample SWC file (e.g., a typical Kenyon cell or projection neuron) and a simplified OBJ mesh of the Drosophila brain.
2. Store them in `assets/brain/vfb/`.
3. Build a Dart parser for SWC to visualize it in the UI.
4. Integrate the view into the Scientist Observatory under a "Biology" tab.
