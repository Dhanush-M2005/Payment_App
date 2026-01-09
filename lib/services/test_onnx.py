import onnxruntime as ort
import numpy as np
import os

def test_onnx_model():
    # Define paths
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(current_dir, "../../"))
    onnx_path = os.path.join(project_root, "assets", "ml", "random_forest_model.onnx")

    if not os.path.exists(onnx_path):
        print(f"Error: ONNX model not found at {onnx_path}")
        return

    # Initialize the session
    print(f"Loading model from: {onnx_path}")
    session = ort.InferenceSession(onnx_path)

    # Get input details
    input_name = session.get_inputs()[0].name
    print(f"Model Input Name: {input_name}")

    # Define test cases (amount, is_in_contacts, hour_of_day, is_new_receiver)
    # Case 1: High Risk (High amount, unknown contact, late night)
    # Case 2: Low Risk (Low amount, in contacts, daytime)
    test_cases = [
        [50000.0, 0, 21, 1],  # Your console data (₹50,000, Not in Contacts, 9 PM)
        [500.0, 1, 14, 1]     # Normal safe transaction
    ]

    print("\n--- Running ONNX Inference Test ---")
    
    for i, features in enumerate(test_cases):
        # Prepare input data (must be float32 and match input shape [None, 4])
        input_data = np.array([features], dtype=np.float32)
        
        # Run prediction
        # The model returns multiple outputs: 'label' and 'probabilities'
        outputs = session.run(None, {input_name: input_data})
        
        prediction = outputs[0][0]  # First output is the label
        probabilities = outputs[1][0] # Second output is a list of dicts or array of probs
        
        risk_type = "FRAUD (1)" if prediction == 1 else "SAFE (0)"
        
        print(f"\nTest Case {i+1}: {features}")
        print(f"Prediction: {risk_type}")
        print(f"Probabilities: {probabilities}")

if __name__ == "__main__":
    test_onnx_model()
