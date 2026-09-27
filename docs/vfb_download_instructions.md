# Virtual Fly Brain (VFB) Data Download Instructions

To populate BrainFly with accurate *Drosophila melanogaster* biological data, you must manually download the exact neuron anatomy files from the Virtual Fly Brain (VFB) platform. 

### 1. Exact VFB Dataset/Page
- **Website:** [Virtual Fly Brain - JRC2018 Adult Brain](https://v2.virtualflybrain.org/)
- **Target Data:** JRC2018 Adult Brain (or FlyWire / Hemibrain mapped to JRC2018)

### 2. What to Click & Which Format to Download
1. Navigate to the VFB interactive 3D viewer for the **Adult Brain**.
2. Query or select a specific neuron (e.g., an Olfactory Projection Neuron like `DA1_lPN` or a Kenyon Cell).
3. On the **Term Info** page for that specific neuron, look for the **Downloads** section.
4. Click on the **SWC** download link. 
   *(Do NOT download NRRD unless you plan to preprocess it offline. OBJ can be downloaded if it represents the whole brain mesh, but is not currently parsed).*

### 3. Where to Put It
Place the downloaded `.swc` file into the following directory in this project:

`assets/brain/vfb/neurons/`

*(Example: `assets/brain/vfb/neurons/DA1_lPN.swc`)*

### 4. What the File Represents
The `.swc` file is a plain-text scientific format representing the 3D morphology of that specific neuron. It contains a list of connected nodes (Soma, Axon, Dendrites) with X, Y, Z coordinates and radii.

### 5. License and Attribution
- Most SWC files downloaded from VFB (derived from Janelia or FlyCircuit datasets) are released under **CC BY 4.0** or **CC0**.
- You must create `assets/brain/vfb/metadata/ATTRIBUTION.txt` and attribute the original lab (e.g., "Data from Janelia Research Campus / FlyWire, accessed via Virtual Fly Brain").

### 6. Suitability for BrainFly
This data is **highly suitable** for BrainFly's Phase 4 (Scientific Observatory visualization). The `SwcParser` currently embedded in the app can mathematically scale and render these exact morphologies natively. It is completely decoupled from the emergent AI logic to ensure no semantic "fake intelligence" is hardcoded into the simulation.
