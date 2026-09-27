import os
import sys
# Note: Requires `neuprint-python` and `navis`
# pip install neuprint-python navis

try:
    from neuprint import Client, fetch_neurons
    import navis
except ImportError:
    print("Please install neuprint-python and navis: pip install neuprint-python navis")
    sys.exit(1)

# Ensure this script is run with the proper dataset permissions.
# You must obtain an auth token from https://neuprint.janelia.org/
# and set it as an environment variable: NEUPRINT_APPLICATION_CREDENTIALS

def main():
    print("--- BrainFly Preprocessing Pipeline: Google/Janelia Male CNS Connectome ---")
    
    # 1. Initialize Client
    # Uses the 'male-cns' dataset from neuprint.janelia.org
    try:
        client = Client('neuprint.janelia.org', dataset='manc:v1.0')
    except Exception as e:
        print("Failed to initialize NeuPrint client. Did you set NEUPRINT_APPLICATION_CREDENTIALS?")
        print(e)
        sys.exit(1)
        
    print("Client initialized successfully.")
    
    # 2. Extract a subset of neurons
    # BrainFly does NOT load 166,000+ meshes into the mobile runtime.
    # We will extract a small, representative sample (e.g., 5 Kenyon Cells or 5 Projection Neurons)
    # for visualization in the Scientist Observatory.
    
    query = """
        MATCH (n:Neuron)
        WHERE n.type = 'Kenyon Cell' OR n.type CONTAINS 'PN'
        RETURN n.bodyId AS bodyId, n.type AS type
        LIMIT 5
    """
    
    print("Fetching metadata for subset...")
    results = client.fetch_custom(query)
    body_ids = results['bodyId'].tolist()
    
    print(f"Found {len(body_ids)} neurons. Fetching SWC skeletons...")
    
    # 3. Download and convert to lightweight SWC
    output_dir = os.path.abspath("../../assets/brain/vfb/neurons/")
    os.makedirs(output_dir, exist_ok=True)
    
    for body_id in body_ids:
        try:
            print(f"Processing Body ID: {body_id}")
            # Fetch skeleton from NeuPrint
            skeleton = client.fetch_skeleton(body_id)
            # Save as SWC
            file_path = os.path.join(output_dir, f"{body_id}.swc")
            # In a real environment, `fetch_skeleton` returns a DataFrame or a navis TreeNeuron
            # We assume it's a pandas dataframe here for the standard `neuprint.fetch_skeleton`
            skeleton.to_csv(file_path, sep=' ', header=False, index=False)
            print(f"Saved: {file_path}")
        except Exception as e:
            print(f"Error processing {body_id}: {e}")

    print("Pipeline complete. SWC files are ready for BrainFly's Biological Brain Layer.")

if __name__ == "__main__":
    main()
