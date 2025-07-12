from flask import Flask, request, jsonify
from flask_cors import CORS
import requests

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

# ✅ Market Price Analysis Route (New)
AGMARKNET_API_KEY = "579b464db66ec23bdd0000014bab96786f8f4f6e5547fb09be3502b8"
AGMARKNET_BASE_URL = "https://api.data.gov.in/resource/f9efb06e-d50b-4c52-9760-e4c2b3d18b08"

@app.route('/market_price', methods=['POST'])
def get_market_price():
    data = request.json
    commodity = data.get('commodity')
    state = data.get('state')
    district = data.get('district')

    params = {
        "api-key": AGMARKNET_API_KEY,
        "format": "json",
        "filters[commodity]": commodity,
        "filters[state]": state,
        "filters[district]": district
    }

    response = requests.get(AGMARKNET_BASE_URL, params=params)

    if response.status_code == 200:
        return jsonify(response.json())
    else:
        return jsonify({"error": "Failed to fetch data"}), 500

# ✅ Run Server
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=10000)
