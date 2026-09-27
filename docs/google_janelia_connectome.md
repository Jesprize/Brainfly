# Google Research & HHMI Janelia Complete Male CNS Connectome

## 1. Official Source & Dataset
- **Source:** Google Research / HHMI Janelia Research Campus / Cambridge Drosophila Connectomics
- **Dataset Name:** MaleCNS v1.0 (Male Drosophila Melanogaster Brain and Central Nervous System Connectome)
- **Publication Date:** September 3, 2026
- **Publication Reference:** "Sexual dimorphism in the complete connectome of the Drosophila male central nervous system" (Cell)

## 2. Download Location & File Formats
- **Primary Portal:** [male-cns.janelia.org](https://male-cns.janelia.org/) and NeuPrint.
- **Formats Provided:**
  - **Neuron Morphology:** SWC files and 3D meshes (OBJ/HDF5/Parquet).
  - **Connectivity:** Adjacency matrices (CSV, Parquet, or SQLite).
  - **Annotations:** Synapse counts, neurotransmitter predictions, brain regions (JSON/CSV).
- **License:** CC-BY 4.0

## 3. Dataset Size & Preprocessing Required
- **Dataset Size:** Massive (>100GB+ for the complete connectome including all raw meshes and dense adjacency matrices).
- **Location Constraints:** **DO NOT** place the raw dataset inside the Flutter mobile runtime.
  - Raw data belongs in `brainfly_data/google_janelia_male_cns/raw/` (outside of the Flutter build path).
  - A preprocessing pipeline script extracts only the specific subset of neurons or regions (e.g., specific subsets of projection neurons) into lightweight JSON/SWC files.
  - These lightweight processed files are then placed into `assets/brain/vfb/neurons/` for the app to load.

## 4. What BrainFly Actually Uses
BrainFly imports this data **strictly as a Biological Brain Reference Layer** for the Scientist Observatory. 
It uses:
- The 3D spatial geometry (SWC) of specific subsets of neurons.
- The metadata (Neuron ID, Name, Region) to display scientific provenance in the UI.

## 5. What Remains Outside the App (And What We DO NOT DO)
- The vast majority of the 125+ million synapses and 166,000+ full meshes remain outside the mobile runtime.
- **CRITICAL ALIFE SEPARATION:** The connectome is **NOT** converted into hard-coded behavioral rules. BrainFly does not map the imported dataset into a "food neuron" or "danger neuron". 
- The artificial-life runtime (Sensors -> ALife Neural Processing -> Motors -> Environment -> Consequences -> Learning) operates completely independently. The imported dataset acts as an anatomical substrate and reference mapping, not a hard-coded intelligence override.

## 6. Previous Test Data Labeling
The previously referenced files (`VGlut-F-200268.swc` and `1000676751.swc`) were **EXTERNAL TEST DATA** derived from FlyCircuit and tutorial datasets. They have been purged and must not be presented as official MaleCNS v1.0 data.
