from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
from requests.auth import HTTPBasicAuth
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

# === FIREBASE SETUP ===
cred = credentials.Certificate("firebase-service-account.json")
firebase_admin.initialize_app(cred)
db = firestore.client()
subscribers_ref = db.collection('subscribers')
call_logs_ref = db.collection('call_logs')  # Logs every call attempt

# === EXOTEL SETUP ===
EXOTEL_SID          = 'hindustaninstituteoftechnology1'
EXOTEL_REGION       = 'sg1'
EXOTEL_API_KEY      = '263092c3668b538b11ce5659bb255af3e199f1ff135de6d1'
EXOTEL_API_PASSWORD = 'e3cdd384370a81aa17ca73913c55a75f3f8a9a2701ff99db'
EXOTEL_FROM_NUMBER  = '04446312604'

# === AGMARKNET SETUP ===
AGMARKNET_API_KEY  = "579b464db66ec23bdd0000014bab96786f8f4f6e5547fb09be3502b8"
AGMARKNET_BASE_URL = "https://api.data.gov.in/resource/f9efb06e-d50b-4c52-9760-e4c2b3d18b08"

# === ROOT ===
@app.route('/')
def home():
    return "✅ Terafarm Backend is running!", 200

# === HEALTH CHECK ===
@app.route('/status')
def status():
    return "API running"

# === CROP RECOMMENDATION ===
def recommend_crops(land_size, budget, duration, state):
    state = state.lower()
    suggestions = []

    if state in ['punjab', 'haryana', 'uttar pradesh']:
        suggestions += ['Wheat', 'Rice']
    elif state in ['maharashtra', 'karnataka', 'andhra pradesh']:
        suggestions += ['Sugarcane', 'Cotton']
    elif state in ['kerala', 'tamil nadu']:
        suggestions += ['Banana', 'Coconut']
    else:
        suggestions += ['Tomato', 'Onion', 'Potato']

    if int(land_size) < 1:
        suggestions = ['Spinach', 'Lettuce']
    elif int(budget) < 5000:
        suggestions += ['Cabbage', 'Okra']

    return list(set(suggestions))

@app.route('/suggest_crop', methods=['POST'])
def suggest_crop():
    data = request.json or {}
    land_size = data.get('land_size')
    budget    = data.get('budget')
    duration  = data.get('duration')
    state     = data.get('state')

    if not all([land_size, budget, duration, state]):
        return jsonify({'error': 'Missing one or more required fields.'}), 400

    crops = recommend_crops(land_size, budget, duration, state)
    return jsonify({'suggested_crops': crops})

# === MARKET PRICE ===
@app.route('/market_price', methods=['POST'])
def get_market_price():
    data = request.json or {}
    commodity = data.get('commodity')
    state     = data.get('state')

    if not all([commodity, state]):
        return jsonify({"error": "Missing required fields: commodity and state"}), 400

    params = {
        "api-key": AGMARKNET_API_KEY,
        "format":  "json",
        "filters[commodity]": commodity,
        "filters[state]":     state,
        "limit":              10
    }

    try:
        resp = requests.get(AGMARKNET_BASE_URL, params=params, timeout=10)
        resp.raise_for_status()
        records = resp.json().get("records", [])
        return jsonify({"prices": records})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# === AVAILABLE COMMODITIES ===
@app.route('/available_commodities', methods=['POST'])
def available_commodities():
    data  = request.json or {}
    state = data.get('state')

    if not state:
        return jsonify({'error': 'State is required.'}), 400

    base_url      = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    last_10_dates = [(datetime.today() - timedelta(days=i)).strftime("%d/%m/%Y") for i in range(10)]

    found = set()
    limit  = 100
    offset = 0
    max_offset = 1000

    try:
        while offset < max_offset:
            params = {
                "api-key": AGMARKNET_API_KEY,
                "format":  "json",
                "limit":   limit,
                "offset":  offset
            }
            resp = requests.get(base_url, params=params, timeout=10)
            if resp.status_code != 200:
                break

            recs = resp.json().get("records", [])
            if not recs:
                break

            for r in recs:
                if (r.get("state", "").lower() == state.lower()
                        and r.get("arrival_date") in last_10_dates):
                    found.add(r.get("commodity", "").title())

            offset += limit

        return jsonify({"commodities": sorted(found)})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# === MARKET PRICE BY COMMODITY ===
@app.route('/market_price_by_commodity', methods=['POST'])
def market_price_by_commodity():
    data      = request.json or {}
    state     = data.get('state')
    commodity = data.get('commodity')

    if not all([state, commodity]):
        return jsonify({'error': 'State and commodity are required.'}), 400

    base_url      = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    last_10_dates = [(datetime.today() - timedelta(days=i)).strftime("%d/%m/%Y") for i in range(10)]

    limit   = 100
    offset  = 0
    out     = []

    try:
        while offset < 1000:
            params = {
                "api-key": AGMARKNET_API_KEY,
                "format":  "json",
                "limit":   limit,
                "offset":  offset
            }
            resp = requests.get(base_url, params=params, timeout=10)
            if resp.status_code != 200:
                break

            recs = resp.json().get("records", [])
            if not recs:
                break

            for r in recs:
                if (r.get("state", "").lower()     == state.lower()
                        and r.get("commodity", "").lower() == commodity.lower()
                        and r.get("arrival_date") in last_10_dates):
                    out.append({
                        "date":        r.get("arrival_date"),
                        "market":      r.get("market"),
                        "modal_price": r.get("modal_price")
                    })

            offset += limit

        sorted_out = sorted(
            out,
            key=lambda x: datetime.strptime(x["date"], "%d/%m/%Y"),
            reverse=True
        )
        return jsonify({"records": sorted_out})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# === EXOTEL SUBSCRIPTION ===
@app.route('/subscribe', methods=['GET', 'POST'])
def subscribe():
    phone = request.values.get('From')
    digit = request.values.get('Digits')

    if not phone:
        return "Missing phone number", 400

    phone = phone.strip().replace('+91', '')[-10:]

    call_logs_ref.add({
        'phone': phone,
        'digit': digit,
        'timestamp': datetime.utcnow()
    })

    if digit == '1':
        subscribers_ref.document(phone).set({
            'subscribed': True,
            'timestamp': datetime.utcnow()
        })
        return "Thanks! You've been subscribed."

    elif digit == '2':
        subscribers_ref.document(phone).delete()
        return "You've been unsubscribed."

    return "Invalid input", 400

# === SMS BROADCAST ===
@app.route('/send_sms_alerts', methods=['GET'])
def send_sms_alerts():
    resp = requests.post(
        'https://your-domain.com/market_price',
        json={'commodity': 'Tomato', 'state': 'Maharashtra'}
    )
    data = resp.json().get('prices', [{}])
    first = data[0] if data else {}
    price_info = f"Tomato Price in {first.get('market', 'market')}: ₹{first.get('modal_price', '-')}/kg"

    users = subscribers_ref.stream()
    numbers = []
    for user in users:
        if user.to_dict().get('subscribed'):
            num = user.id
            if not num.startswith('+'):
                num = '+91' + num[-10:]
            numbers.append(num)

    for number in numbers:
        sms_url = f"https://{EXOTEL_REGION}.exotel.com/v1/Accounts/{EXOTEL_SID}/Sms/send"
        payload = {
            'From': EXOTEL_FROM_NUMBER,
            'To': number,
            'Body': price_info
        }
        auth = HTTPBasicAuth(EXOTEL_API_KEY, EXOTEL_API_PASSWORD)
        response = requests.post(sms_url, data=payload, auth=auth)
        print(f"Sent to {number}: {response.text}")

    return jsonify({'status': 'done', 'recipients': len(numbers)})

# === APP ENTRYPOINT ===
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
