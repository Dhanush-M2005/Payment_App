import random
import pandas as pd

data = []

for _ in range(5000):
    amount = random.choice([50, 200, 500, 2000, 5000, 10000, 20000])
    is_in_contacts = random.choice([0, 1])
    qr_type = random.choice([0, 1])  # 0 = P2P, 1 = Merchant
    hour_of_day = random.randint(0, 23)

    # Cold-start assumptions
    is_new_receiver = 1
    scan_frequency = 1

    # Rule-based labeling logic
    label = 1 if (
        amount >= 10000 and is_in_contacts == 0 or
        hour_of_day < 5 or
        qr_type == 1 and amount >= 5000
    ) else 0

    data.append([
        amount,
        is_in_contacts,
        qr_type,
        hour_of_day,
        is_new_receiver,
        scan_frequency,
        label
    ])

df = pd.DataFrame(
    data,
    columns=[
        'amount',
        'is_in_contacts',
        'qr_type',
        'hour_of_day',
        'is_new_receiver',
        'scan_frequency',
        'label'
    ]
)

# Save dataset
df.to_csv("cold_start_dataset.csv", index=False)

print("Cold-start dataset generated successfully.")
