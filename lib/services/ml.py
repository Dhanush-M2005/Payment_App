import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import os
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType
import onnx

# ==========================================
# 1. Data Generation (Using your logic)
# ==========================================
def generate_data(n_samples=5000):
    np.random.seed(42)
    
    # Base Features
    amounts = np.random.exponential(scale=4000, size=n_samples)
    amounts = np.clip(amounts, 10, 10000).round(2)
    is_in_contacts = np.random.choice([0, 1], size=n_samples, p=[0.6, 0.4])
    hour_of_day = np.random.randint(0, 24, size=n_samples)
    is_new_receiver = np.ones(n_samples, dtype=int) # Always 1 based on your script

    # Risk Scoring Logic (Ground Truth)
    risk_amount = (amounts >= 5000).astype(int) * 0.6
    risk_not_in_contacts = (is_in_contacts == 0).astype(int) * 0.6
    risk_time = ((hour_of_day < 6) | (hour_of_day >= 23)).astype(int) * 0.4
    
    # Interactions
    risk_combo_high_amt_unknown = ((amounts >= 5000) & (is_in_contacts == 0)).astype(int) * 0.8
    risk_combo_night_unknown = ((hour_of_day < 6) & (is_in_contacts == 0)).astype(int) * 0.5

    total_risk = (risk_amount + risk_not_in_contacts + risk_time + 
                  risk_combo_high_amt_unknown + risk_combo_night_unknown)

    # Noise and Labeling
    noise = np.random.normal(0, 0.25, n_samples)
    final_score = total_risk + noise
    labels = (final_score > 1.2).astype(int)

    df = pd.DataFrame({
        'amount': amounts,
        'is_in_contacts': is_in_contacts,
        'hour_of_day': hour_of_day,
        'is_new_receiver': is_new_receiver,
        'label': labels
    })
    
    return df

# Generate the dataset
df = generate_data(5000)
print(f"Data Generated. Shape: {df.shape}")
print("-" * 30)

# ==========================================
# 2. Data Preprocessing
# ==========================================

# Define Features (X) and Target (y)
X = df[['amount', 'is_in_contacts', 'hour_of_day', 'is_new_receiver']]
y = df['label']

# Split into Training (80%) and Testing (20%) sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

print(f"Training samples: {X_train.shape[0]}")
print(f"Testing samples:  {X_test.shape[0]}")
print("-" * 30)

# ==========================================
# 3. Model Training (Random Forest)
# ==========================================

# Initialize the model
# n_estimators=100 means it creates 100 decision trees
rf_model = RandomForestClassifier(n_estimators=100, random_state=42)

# Train the model
rf_model.fit(X_train, y_train)
print("Random Forest Model Trained Successfully.")
print("-" * 30)

# ==========================================
# 4. Evaluation
# ==========================================

# Make predictions on the test set
y_pred = rf_model.predict(X_test)

# Calculate metrics
accuracy = accuracy_score(y_test, y_pred)
conf_matrix = confusion_matrix(y_test, y_pred)
report = classification_report(y_test, y_pred)

print(f"Accuracy: {accuracy:.2%}")
print("\nConfusion Matrix:")
print(conf_matrix)
print("\nClassification Report:")
print(report)

# ==========================================
# 5. Feature Importance Visualization
# ==========================================
# This shows which factors drove the Fraud decision
feature_importances = pd.Series(rf_model.feature_importances_, index=X.columns).sort_values(ascending=False)

plt.figure(figsize=(8, 5))
sns.barplot(x=feature_importances, y=feature_importances.index)
plt.title("Feature Importance in Fraud Detection")
plt.xlabel("Importance Score")
plt.ylabel("Features")
# plt.show()
plt.savefig("feature_importance.png")
print("Feature importance plot saved as 'feature_importance.png'")

# ==========================================
# 6. Test a Specific Transaction
# ==========================================
# Example: High Amount, Not in Contacts, 2 AM (Should be Fraud/1)
new_transaction = pd.DataFrame({
    'amount': [9500.00],
    'is_in_contacts': [0],
    'hour_of_day': [2],
    'is_new_receiver': [1]
})

prediction = rf_model.predict(new_transaction)
probability = rf_model.predict_proba(new_transaction)

print("\n--- Test Prediction ---")
print(f"Transaction: ₹{new_transaction['amount'][0]}, Contact: {new_transaction['is_in_contacts'][0]}, Hour: {new_transaction['hour_of_day'][0]}")
print(f"Prediction: {'Fraud (1)' if prediction[0] == 1 else 'Safe (0)'}")
print(f"Probability of Fraud: {probability[0][1]:.2%}")

# ==========================================
# 7. Export Model to ONNX
# ==========================================
# Define the input type for ONNX (4 features: amount, is_in_contacts, hour_of_day, is_new_receiver)
initial_type = [('float_input', FloatTensorType([None, 4]))]
# target_opset=15 ensures compatibility with ONNX Runtime versions that support up to IR 9
onx = convert_sklearn(rf_model, initial_types=initial_type, target_opset=15)

# Define the path to save the ONNX model
# ml.py is in lib/services/, so we go up two levels to reach the project root
current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(current_dir, "../../"))
assets_ml_path = os.path.join(project_root, "assets", "ml")

if not os.path.exists(assets_ml_path):
    os.makedirs(assets_ml_path)

onnx_filename = "random_forest_model.onnx"
onnx_path = os.path.join(assets_ml_path, onnx_filename)

# Save the ONNX model
with open(onnx_path, "wb") as f:
    f.write(onx.SerializeToString())

print(f"\nONNX model exported successfully to: {onnx_path}")