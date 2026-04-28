// This script seeds the local mock data into your Firestore database.
// To use:
// 1. You must have a service account key JSON file from your Firebase Project settings.
// 2. Set GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
// 3. Run: node seed_data.js

const admin = require("firebase-admin");

// Initialize Firebase Admin without explicit credentials, relying on GOOGLE_APPLICATION_CREDENTIALS
try {
  admin.initializeApp();
} catch (error) {
  console.error("Error initializing Firebase:", error.message);
  console.error("Did you set GOOGLE_APPLICATION_CREDENTIALS?");
  process.exit(1);
}

const db = admin.firestore();

const mockDashboard = {
  farmerName: 'Ramesh Kumar',
  location: 'Mandya, Karnataka',
  crisisLevel: 'medium', // Storing enum as string
};

const mockMarket = {
  crops: [
    { name: 'Tomato', emoji: '🍅', price: 42.50, changePercent: 12.3, badge: 'Sell', unit: '₹/kg', weeklyData: [28.0, 30.0, 33.0, 35.0, 38.0, 40.0, 42.5] },
    { name: 'Onion', emoji: '🧅', price: 35.00, changePercent: -5.2, badge: 'Hold', unit: '₹/kg', weeklyData: [40.0, 38.0, 37.0, 36.0, 35.5, 35.2, 35.0] },
    { name: 'Rice', emoji: '🌾', price: 28.75, changePercent: 2.1, badge: 'Wait', unit: '₹/kg', weeklyData: [26.0, 26.5, 27.0, 27.5, 28.0, 28.5, 28.75] },
    { name: 'Wheat', emoji: '🌿', price: 24.00, changePercent: -1.8, badge: 'Hold', unit: '₹/kg', weeklyData: [25.5, 25.0, 24.8, 24.5, 24.3, 24.1, 24.0] },
  ],
  mandis: [
    { name: 'Mandya APMC', distance: '8 km', contact: '+91 98765 43210' },
    { name: 'Mysore Mandi', distance: '32 km', contact: '+91 98765 43211' },
  ],
};

const mockClimate = {
  forecast: [
    { day: 'Mon', condition: 'sunny',  tempCelsius: 34, rainPercent: 10 },
    { day: 'Tue', condition: 'sunny',  tempCelsius: 33, rainPercent: 15 },
    { day: 'Wed', condition: 'cloudy', tempCelsius: 31, rainPercent: 45 },
    { day: 'Thu', condition: 'stormy', tempCelsius: 28, rainPercent: 80 },
    { day: 'Fri', condition: 'stormy', tempCelsius: 27, rainPercent: 85 },
    { day: 'Sat', condition: 'cloudy', tempCelsius: 29, rainPercent: 40 },
    { day: 'Sun', condition: 'sunny',  tempCelsius: 32, rainPercent: 20 },
  ],
  regional: {
    humidityPercent: 72, windKmh: 14, uvIndex: 6, soilTempCelsius: 26,
  },
};

const mockPostHarvest = {
  spoilageRisk: 0.34,
  currentHumidityPercent: 72,
  tips: [
    { crop: 'Tomato', emoji: '🍅', risk: 'high', tip: 'Store at 12-15°C with 85-90% humidity. Avoid direct sunlight. Use ventilated crates.' },
    { crop: 'Onion', emoji: '🧅', risk: 'medium', tip: 'Cure in shade for 2-3 days. Store in mesh bags with good airflow at 25-30°C.' },
    { crop: 'Rice', emoji: '🌾', risk: 'low', tip: 'Dry to 14% moisture. Store in airtight containers. Keep off the floor on pallets.' },
    { crop: 'Wheat', emoji: '🌿', risk: 'low', tip: 'Clean and dry thoroughly. Store in metal bins. Check for weevils every 2 weeks.' },
  ],
};

async function seedData() {
  try {
    console.log("Starting data seed...");

    await db.collection("dashboard").doc("farmer_profile").set(mockDashboard);
    console.log("Seeded dashboard data.");

    await db.collection("market").doc("latest").set(mockMarket);
    console.log("Seeded market data.");

    await db.collection("climate").doc("latest").set(mockClimate);
    console.log("Seeded climate data.");

    await db.collection("post_harvest").doc("latest").set(mockPostHarvest);
    console.log("Seeded post-harvest data.");

    console.log("Data seeding complete!");
  } catch (error) {
    console.error("Error seeding data:", error);
  } finally {
    process.exit(0);
  }
}

seedData();
