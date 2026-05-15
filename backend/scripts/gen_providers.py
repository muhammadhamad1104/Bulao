import json
import random
from pathlib import Path
from datetime import datetime, timedelta

random.seed(42) # reproducible

NEIGHBORHOODS = {
    "F-6": (33.7218, 73.0667), "F-7": (33.7176, 73.0531), "F-8": (33.7068, 73.0337),
    "F-10": (33.6905, 73.0205), "F-11": (33.6850, 73.0095), "G-7": (33.6979, 73.0683),
    "G-9": (33.6892, 73.0337), "G-10": (33.6750, 73.0250), "G-11": (33.6650, 73.0150),
    "G-13": (33.6584, 73.0479), "Bahria Town Phase 4": (33.5210, 73.0900),
    "DHA Islamabad Phase 2": (33.5100, 73.1500), "Saddar Rawalpindi": (33.5950, 73.0480),
    "DHA Karachi Phase 6": (24.8020, 67.0643), "DHA Lahore Phase 5": (31.4621, 74.4087)
}

SERVICE_POOL = [
    "plumber","electrician","ac_technician","geyser_technician",
    "carpenter","painter","beautician","tutor","appliance_repair","gas_leak_specialist"
]

SPECIALIZATIONS = {
    "ac_technician": ["inverter_ac","split_ac","window_ac","central_ac"],
    "plumber": ["geyser_leak","tap_replacement","pipe_burst","drain_cleaning"],
    "electrician": ["house_wiring","switchboard","ups_install","fan_install"],
    "beautician": ["bridal","engagement","party_makeup","hair_styling","facial"],
    "tutor": ["o_level_math","a_level_business","quran","english"],
}

FIRST_NAMES_M = ["Ali","Ahmed","Hassan","Bilal","Usman","Fahad","Tariq","Imran","Saad","Zain"]
FIRST_NAMES_F = ["Ayesha","Sana","Fatima","Hina","Maria","Nida","Sara","Zoya","Iqra","Mahnoor"]
LAST_NAMES = ["Khan","Ali","Hussain","Ahmed","Malik","Sheikh","Qureshi","Butt","Mughal","Shah"]

def gen_provider(i: int) -> dict:
    neighborhood = random.choice(list(NEIGHBORHOODS.keys()))
    lat, lng = NEIGHBORHOODS[neighborhood]
    lat += random.uniform(-0.01, 0.01)
    lng += random.uniform(-0.01, 0.01)
    
    gender = random.choice(["male","female"])
    fname = random.choice(FIRST_NAMES_M if gender == "male" else FIRST_NAMES_F)
    lname = random.choice(LAST_NAMES)
    
    primary_service = random.choice(SERVICE_POOL)
    services = [primary_service]
    if random.random() < 0.3:
        extra = random.choice([s for s in SERVICE_POOL if s != primary_service])
        services.append(extra)
        
    specs = SPECIALIZATIONS.get(primary_service, [])
    chosen_specs = random.sample(specs, k=min(2, len(specs))) if specs else []
    
    rating = round(random.gauss(4.3, 0.35), 1)
    rating = max(3.5, min(5.0, rating))
    
    slots = []
    now = datetime.now()
    for _ in range(random.randint(3,6)):
        day_offset = random.randint(0,6)
        hour = random.choice([9,10,11,14,15,16,17])
        slot_time = (now + timedelta(days=day_offset)).replace(hour=hour, minute=0, second=0, microsecond=0)
        slots.append(slot_time.isoformat() + "+05:00")
        
    city = "Islamabad"
    if "Rawalpindi" in neighborhood or "Pindi" in neighborhood:
        city = "Rawalpindi"
    elif "Karachi" in neighborhood:
        city = "Karachi"
    elif "Lahore" in neighborhood:
        city = "Lahore"

    return {
        "id": f"prov_{i:03d}",
        "name": f"{fname} {lname} {primary_service.replace('_',' ').title()}",
        "service_categories": services,
        "specializations": chosen_specs,
        "lat": round(lat, 6),
        "lng": round(lng, 6),
        "neighborhood": neighborhood,
        "city": city,
        "rating": rating,
        "completed_jobs": random.randint(20, 250),
        "completed_jobs_by_neighborhood": {neighborhood: random.randint(5, 80)},
        "on_time_score": round(random.uniform(0.75, 1.0), 2),
        "cancellation_rate": round(random.uniform(0.0, 0.15), 2),
        "review_recency_days": random.randint(1, 90),
        "risk_score": round(random.uniform(0.02, 0.30), 2),
        "current_workload": round(random.uniform(0.0, 1.0), 2),
        "available_slots": sorted(slots),
        "phone": f"+9233{random.randint(10000000, 99999999)}",
        "gender": gender,
        "years_experience": random.randint(1, 25),
        "languages": ["urdu", "english"] if random.random() > 0.3 else ["urdu"],
        "base_visit_fee_pkr": random.choice([300, 400, 500, 600, 800]),
        "rate_per_hour_pkr": random.choice([800, 1000, 1200, 1500, 2000, 2500]),
        "price_range_pkr": [random.randint(800, 1500), random.randint(3000, 8000)],
        "verified": random.random() > 0.1
    }

if __name__ == "__main__":
    providers = [gen_provider(i+1) for i in range(100)]
    
    # Ensure distributions
    # Force 15 female
    female_count = sum(1 for p in providers if p["gender"] == "female")
    while female_count < 15:
        p = random.choice([p for p in providers if p["gender"] == "male"])
        p["gender"] = "female"
        p["name"] = f"{random.choice(FIRST_NAMES_F)} {random.choice(LAST_NAMES)} {p['service_categories'][0].replace('_',' ').title()}"
        female_count += 1
        
    Path("app/data/providers.json").write_text(json.dumps(providers, indent=2, ensure_ascii=False))
    Path("app/data/neighborhoods.json").write_text(json.dumps({k: {"lat": v[0], "lng": v[1]} for k, v in NEIGHBORHOODS.items()}, indent=2))
    print(f"Generated {len(providers)} providers across {len(NEIGHBORHOODS)} neighborhoods.")
