import pandas as pd
import numpy as np

def generate_csv(filename='training_data.csv', n_samples=5000):
    # Reproducibility
    np.random.seed(42)

    # ---------------------------------------------------------
    # 1. Generate Base Features (FIRST 10 PAYMENTS SCENARIO)
    # ---------------------------------------------------------

    # Amount: shifted distribution to include higher values (up to ~20,000)
    # This makes 10,000 a meaningful risk threshold
    amounts = np.random.exponential(scale=4000, size=n_samples)
    amounts = np.clip(amounts, 10, 10000).round(2)

    # is_in_contacts = main trust signal
    # First 10 payments → more unknown receivers
    is_in_contacts = np.random.choice([0, 1], size=n_samples, p=[0.6, 0.4])

    # Hour of day: 0–23
    hour_of_day = np.random.randint(0, 24, size=n_samples)

    # FIRST 10 PAYMENTS → always new receiver
    is_new_receiver = np.ones(n_samples, dtype=int)

    # ---------------------------------------------------------
    # 2. Risk Scoring Logic
    # Focus on is_in_contacts + high amount (₹10,000)
    # ---------------------------------------------------------

    # A. High amount (₹10,000+)
    risk_amount = (amounts >= 5000).astype(int) * 0.6

    # B. NOT in contacts (primary risk)
    risk_not_in_contacts = (is_in_contacts == 0).astype(int) * 0.6

    # C. Weird hours (11 PM – 6 AM)
    risk_time = ((hour_of_day < 6) | (hour_of_day >= 23)).astype(int) * 0.4

    # ---------------------------------------------------------
    # 2(A). Interaction: High amount + NOT in contacts
    # ---------------------------------------------------------
    risk_combo_high_amt_unknown = (
        (amounts >= 5000) & (is_in_contacts == 0)
    ).astype(int) * 0.8

    # ---------------------------------------------------------
    # 2(B). Interaction: Late night + NOT in contacts
    # ---------------------------------------------------------
    risk_combo_night_unknown = (
        (hour_of_day < 6) & (is_in_contacts == 0)
    ).astype(int) * 0.5

    # ---------------------------------------------------------
    # 3. Total Risk + Noise
    # ---------------------------------------------------------
    total_risk = (
        risk_amount +
        risk_not_in_contacts +
        risk_time +
        risk_combo_high_amt_unknown +
        risk_combo_night_unknown
    )

    # Noise for realism
    noise = np.random.normal(0, 0.25, n_samples)
    final_score = total_risk + noise

    # ---------------------------------------------------------
    # 4. Label Generation
    # ---------------------------------------------------------
    # 1 = Fraud / Warn
    # 0 = Safe
    labels = (final_score > 1.2).astype(int)

    # ---------------------------------------------------------
    # 5. Save CSV
    # ---------------------------------------------------------
    df = pd.DataFrame({
        'amount': amounts,
        'is_in_contacts': is_in_contacts,
        'hour_of_day': hour_of_day,
        'is_new_receiver': is_new_receiver,
        'label': labels
    })

    df.to_csv(filename, index=False)

    print(f"File '{filename}' generated successfully")
    print(f"Total rows      : {len(df)}")
    print(f"Fraud rate      : {df['label'].mean():.2%}")
    print(f"High-value txns : {(df['amount'] >= 10000).mean():.2%}")

    return df


if __name__ == "__main__":
    df = generate_csv(n_samples=5000)
    print("\nFirst 5 rows:")
    print(df.head())
