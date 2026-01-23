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


def generate_data(n_samples=5000):
    np.random.seed(42)
    
    
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


accuracy = accuracy_score(y_test, y_pred)
conf_matrix = confusion_matrix(y_test, y_pred)
report = classification_report(y_test, y_pred)

print(f"Accuracy: {accuracy:.2%}")
print("\nConfusion Matrix:")
print(conf_matrix)
print("\nClassification Report:")
print(report)


feature_importances = pd.Series(rf_model.feature_importances_, index=X.columns).sort_values(ascending=False)

plt.figure(figsize=(8, 5))
sns.barplot(x=feature_importances, y=feature_importances.index)
plt.title("Feature Importance in Fraud Detection")
plt.xlabel("Importance Score")
plt.ylabel("Features")
# plt.show()
plt.savefig("feature_importance.png")
print("Feature importance plot saved as 'feature_importance.png'")


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



# Define the input type for ONNX (4 features: amount, is_in_contacts, hour_of_day, is_new_receiver)
initial_type = [('float_input', FloatTensorType([None, 4]))]
# target_opset=15 ensures compatibility with ONNX Runtime versions that support up to IR 9
onx = convert_sklearn(rf_model, initial_types=initial_type, target_opset=15)


current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(current_dir, "../../"))
assets_ml_path = os.path.join(project_root, "assets", "ml")

if not os.path.exists(assets_ml_path):
    os.makedirs(assets_ml_path)

onnx_filename = "random_forest_model.onnx"
onnx_path = os.path.join(assets_ml_path, onnx_filename)


with open(onnx_path, "wb") as f:
    f.write(onx.SerializeToString())

print(f"\nONNX model exported successfully to: {onnx_path}")

# ==========================================
# 5. Adaptive Fraud System (Self-Training)
# ==========================================

class AdaptiveFraudSystem:
    def __init__(self, base_model):
        self.base_model = base_model
        # Dictionary to store history per user
        # Format: {'user_id': DataFrame of past transactions}
        self.user_profiles = {}

    def predict(self, user_id, current_txn):
        """
        current_txn: dict e.g. {'amount': 12000, 'is_in_contacts': 0...}
        """
        # Convert dict to DataFrame for the model
        txn_df = pd.DataFrame([current_txn])
        
        # 1. Get Base Probability (Cold Start Score)
        # We use probability (0.0 to 1.0) instead of binary prediction for fine-tuning
        base_prob = self.base_model.predict_proba(txn_df)[0][1] # Probability of Fraud (1)

        # 2. Check if user is new (Cold Start Phase)
        if user_id not in self.user_profiles or len(self.user_profiles[user_id]) < 10:
            print(f"[Cold Start] Using generic model rules.")
            is_fraud = 1 if base_prob > 0.5 else 0
            return is_fraud, base_prob

        # 3. Adaptive Phase (11th+ Payment)
        else:
            print(f"[Adaptive] Analyzing history ({len(self.user_profiles[user_id])} past txns)...")
            history = self.user_profiles[user_id]
            
            # --- PERSONALIZATION LOGIC ---
            
            # A. High Value Comfort Analysis
            # Check if user has safely sent amounts similar or higher than current
            # A. High Value Comfort Analysis
            # Check if user has safely sent amounts similar or higher than current
            # CRITICAL UPDATE: Only apply this trust if the CURRENT receiver is NOT new (or is in contacts).
            # If sending to a NEW receiver, High Amount is ALWAYS risky, regardless of past spending habits.
            
            amount_trust_factor = 0.0
            if current_txn['amount'] > 10000:
                # Check 1: Is the receiver known/safe?
                if current_txn['is_new_receiver'] == 0 or current_txn['is_in_contacts'] == 1:
                    
                     safe_high_value_txns = history[
                        (history['amount'] >= 10000) & 
                        (history['label'] == 0) 
                    ]
                     
                     if len(safe_high_value_txns) >= 3: 
                        print(" -> Pattern found: User makes safe high-value payments to KNOWN parties.")
                        amount_trust_factor = 0.25 
                else:
                    print(" -> High Amount to NEW Receiver. STRICT WARNING enforced.")

            # B. New Receiver Comfort Analysis
            # Check if user frequently pays new receivers safely
            safe_new_receiver_txns = history[
                (history['is_new_receiver'] == 1) & 
                (history['label'] == 0)
            ]
            
            receiver_trust_factor = 0.0
            if current_txn['is_new_receiver'] == 1:
                # If > 50% of their past new-receiver payments were safe
                total_new = len(history[history['is_new_receiver'] == 1])
                if total_new > 0:
                    safe_ratio = len(safe_new_receiver_txns) / total_new
                    if safe_ratio > 0.8: # 80% success rate with new people
                        print(" -> Pattern found: User trusts new receivers.")
                        receiver_trust_factor = 0.20 # Reduce fraud probability by 20%

            # C. Known Receiver Amount Consistency
            # If the receiver is NOT new, check if we have sent similar amounts to known receivers before.
            # In a real production system, this would filter by the specific 'upi_id'. 
            # With current features, we treat "all known receivers" as the history context.
            
            consistency_trust_factor = 0.0
            if current_txn['is_new_receiver'] == 0:
                # Get all safe payments to known receivers
                safe_known_receiver_txns = history[
                    (history['is_new_receiver'] == 0) & 
                    (history['label'] == 0)
                ]
                
                if len(safe_known_receiver_txns) > 0:
                    max_past_amount = safe_known_receiver_txns['amount'].max()
                    
                    # Heuristic: If current amount is <= 1.5x the max previously sent to known receivers
                    if current_txn['amount'] <= (max_past_amount * 1.5):
                        print(f" -> Pattern found: Amount {current_txn['amount']} is within range of past known receiver payments (Max: {max_past_amount}).")
                        consistency_trust_factor = 0.30 # Significant trust boost for consistent behavior
                        
            # --- CALCULATE FINAL PERSONALIZED SCORE ---
            
            adjusted_prob = base_prob - amount_trust_factor - receiver_trust_factor - consistency_trust_factor
            
            # Clamp between 0 and 1
            adjusted_prob = max(0.0, min(1.0, adjusted_prob))
            
            print(f" -> Base Risk: {base_prob:.2f} | Adjusted Risk: {adjusted_prob:.2f}")
            
            is_fraud = 1 if adjusted_prob > 0.5 else 0
            return is_fraud, adjusted_prob

    def update_history(self, user_id, txn_data, actual_label):
        """
        After the transaction settles, we learn from it.
        actual_label: 0 = Safe, 1 = Fraud
        """
        txn_data['label'] = actual_label
        
        if user_id not in self.user_profiles:
            self.user_profiles[user_id] = pd.DataFrame([txn_data])
        else:
            self.user_profiles[user_id] = pd.concat([
                self.user_profiles[user_id], 
                pd.DataFrame([txn_data])
            ], ignore_index=True)

# ==========================================
# 6. Simulation
# ==========================================

print("\n" + "="*50)
print("STARTING SIMULATION")
print("="*50)

# Initialize System
# Note: rf_model is the trained Random Forest from the base code
system = AdaptiveFraudSystem(rf_model)
USER_ID = "User_A_HighSpender"

print("=== PHASE 1: COLD START (First 10 Transactions) ===")
# User tries to do High Value transactions (12,000)
# Base model hates this (High Risk)
for i in range(1, 11):
    current_txn = {
        'amount': 12000.00,       # High Amount
        'is_in_contacts': 0,      # Unknown receiver
        'hour_of_day': 14,        # Normal time
        'is_new_receiver': 1
    }
    
    print(f"\nTxn #{i}: Requesting ₹12,000...")
    prediction, prob = system.predict(USER_ID, current_txn)
    
    if prediction == 1:
        print("System: 🔴 BLOCKED (High Risk)")
    else:
        print("System: 🟢 ALLOWED")
        
    # FEEDBACK LOOP: 
    # User complains, says "This was me! It's Safe!"
    # We update history with label = 0 (Safe)
    system.update_history(USER_ID, current_txn, actual_label=0)

print("\n" + "="*50)
print("=== PHASE 2: ADAPTIVE LEARNING (11th Transaction) ===")
print("="*50)

# Now comes the 11th transaction. Same details.
# The base model still hates it, but the Adaptive System should override it.
txn_11 = {
    'amount': 12000.00,
    'is_in_contacts': 0,
    'hour_of_day': 14,
    'is_new_receiver': 1
}

print(f"\nTxn #11: Requesting ₹12,000...")
prediction, prob = system.predict(USER_ID, txn_11)

if prediction == 1:
    print("System: 🔴 BLOCKED")
else:
    print("System: 🟢 ALLOWED (Personalized Approval)")
    print("Reason: Model learned that User_A safely spends >10k.")

print("\n" + "="*50)
print("=== SIMULATION 2: User_B (Low Spender) ===")
print("="*50)

USER_ID_B = "User_B_LowSpender"

# Phase 1: Small Transactions (User B only buys coffee/snacks)
print("--- Phase 1: Small Transactions (First 10) ---")
for i in range(1, 11):
    current_txn = {
        'amount': 200.00,         # Low Amount
        'is_in_contacts': 1,      # Known receiver (Safe)
        'hour_of_day': 10,        # Morning
        'is_new_receiver': 0
    }
    # We update history with label = 0 (Safe)
    system.update_history(USER_ID_B, current_txn, actual_label=0)

print(f"Uploaded 10 safe small transactions for {USER_ID_B}.")

# Phase 2: Sudden High Value Transaction
# Matches User A's 11th transaction exactly
txn_11_B = {
    'amount': 12000.00,
    'is_in_contacts': 0,
    'hour_of_day': 14,
    'is_new_receiver': 1
}

print(f"\nTxn #11 (User B): Requesting ₹12,000...")
prediction, prob = system.predict(USER_ID_B, txn_11_B)

if prediction == 1:
    print("System: 🔴 BLOCKED (Correct)")
    print("Reason: User_B has NO history of high spending. Adaptive layer did NOT interfere.")
else:
    print("System: 🟢 ALLOWED (Incorrect)")