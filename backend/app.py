from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Dummy crop recommendation logic (replace with ML model if needed)
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

@app.route('/suggest_crop', methods=['POST'])
def suggest_crop():
    data = request.json
    land_size = data.get('land_size')
    budget = data.get('budget')
    duration = data.get('duration')
    weather = data.get('weather')

    crops = recommend_crops(land_size, budget, duration, weather)
    return jsonify({'suggested_crops': crops})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=10000)
