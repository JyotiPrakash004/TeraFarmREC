from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

# ✅ Status check
@app.route('/status')
def status():
    return "API running"

# ✅ Dummy Crop Recommendation Logic
def recommend_crops(land_size, budget, duration, weather):
    suggestions = []
    if weather.lower() in ['sunny', 'hot']:
        if int(duration) <= 3:
            suggestions.append('Tomato')
        else:
            suggestions.append('Rice')
    if weather.lower() in ['cold', 'rainy']:
        suggestions.append('Wheat')
        if int(budget) > 10000:
            suggestions.append('Broccoli')
    if int(land_size) < 1:
        suggestions = ['Spinach', 'Lettuce']
    return list(set(suggestions))

# ✅ Crop Suggestion Route
@app.route('/suggest_crop', methods=['POST'])
def suggest_crop():
    data = request.json
    land_size = data.get('land_size')
    budget = data.get('budget')
    duration = data.get('duration')
    weather = data.get('weather')
    crops = recommend_crops(land_size, budget, duration, weather)
    return jsonify({'suggested_crops': crops})

# ✅ Market Price Route (Default API)
AGMARKNET_API_KEY = "579b464db66ec23bdd0000014bab96786f8f4f6e5547fb09be3502b8"
AGMARKNET_BASE_URL = "https://api.data.gov.in/resource/f9efb06e-d50b-4c52-9760-e4c2b3d18b08"

@app.route('/market_price', methods=['POST'])
def get_market_price():
    data = request.json
    commodity = data.get('commodity')
    state = data.get('state')

    if not all([commodity, state]):
        return jsonify({"error": "Missing required fields: commodity and state"}), 400

    params = {
        "api-key": AGMARKNET_API_KEY,
        "format": "json",
        "filters[commodity]": commodity,
        "filters[state]": state,
        "limit": 10
    }

    try:
        response = requests.get(AGMARKNET_BASE_URL, params=params)
        response.raise_for_status()
        result = response.json()
        records = result.get("records", [])
        return jsonify({"prices": records})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ✅ NEW: Get Available Commodities in Last 10 Days for a State
@app.route('/available_commodities', methods=['POST'])
def available_commodities():
    data = request.json
    state = data.get('state')

    if not state:
        return jsonify({'error': 'State is required.'}), 400

    base_url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    last_10_dates = [(datetime.today() - timedelta(days=i)).strftime("%d/%m/%Y") for i in range(10)]

    found_commodities = set()
    limit = 100
    offset = 0
    max_records = 5000

    try:
        while offset < max_records:
            params = {
                "api-key": AGMARKNET_API_KEY,
                "format": "json",
                "limit": limit,
                "offset": offset
            }
            res = requests.get(base_url, params=params)
            if res.status_code != 200:
                break

            records = res.json().get("records", [])
            if not records:
                break

            for r in records:
                if (
                    r.get("state", "").lower() == state.lower()
                    and r.get("arrival_date") in last_10_dates
                ):
                    found_commodities.add(r.get("commodity", "").title())

            offset += limit

        return jsonify({"commodities": sorted(list(found_commodities))})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ✅ NEW: Get Price Data by State + Commodity (Last 10 Days)
@app.route('/market_price_by_commodity', methods=['POST'])
def market_price_by_commodity():
    data = request.json
    state = data.get('state')
    commodity = data.get('commodity')

    if not state or not commodity:
        return jsonify({'error': 'State and commodity are required.'}), 400

    base_url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    last_10_dates = [(datetime.today() - timedelta(days=i)).strftime("%d/%m/%Y") for i in range(10)]

    limit = 100
    offset = 0
    max_records = 5000
    filtered_records = []

    try:
        while offset < max_records:
            params = {
                "api-key": AGMARKNET_API_KEY,
                "format": "json",
                "limit": limit,
                "offset": offset
            }
            res = requests.get(base_url, params=params)
            if res.status_code != 200:
                break
            records = res.json().get("records", [])
            if not records:
                break

            for r in records:
                if (
                    r.get("state", "").lower() == state.lower()
                    and r.get("commodity", "").lower() == commodity.lower()
                    and r.get("arrival_date") in last_10_dates
                ):
                    filtered_records.append({
                        "date": r.get("arrival_date"),
                        "market": r.get("market"),
                        "modal_price": r.get("modal_price")
                    })

            offset += limit

        sorted_records = sorted(
            filtered_records,
            key=lambda x: datetime.strptime(x["date"], "%d/%m/%Y"),
            reverse=True
        )

        return jsonify({"records": sorted_records})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ✅ Run Server
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=10000)
