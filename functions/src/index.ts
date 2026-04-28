import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const getDashboardData = functions.https.onCall(async (data, context) => {
  try {
    const doc = await admin.firestore().collection("dashboard").doc("farmer_profile").get();
    if (!doc.exists) {
      throw new functions.https.HttpsError("not-found", "Dashboard data not found.");
    }
    return doc.data();
  } catch (error) {
    console.error("Error fetching dashboard data:", error);
    throw new functions.https.HttpsError("internal", "Unable to fetch dashboard data.");
  }
});

export const getMarketData = functions.https.onCall(async (data, context) => {
  try {
    const doc = await admin.firestore().collection("market").doc("latest").get();
    if (!doc.exists) {
      throw new functions.https.HttpsError("not-found", "Market data not found.");
    }
    return doc.data();
  } catch (error) {
    console.error("Error fetching market data:", error);
    throw new functions.https.HttpsError("internal", "Unable to fetch market data.");
  }
});

export const getClimateData = functions.https.onCall(async (data, context) => {
  try {
    const doc = await admin.firestore().collection("climate").doc("latest").get();
    if (!doc.exists) {
      throw new functions.https.HttpsError("not-found", "Climate data not found.");
    }
    return doc.data();
  } catch (error) {
    console.error("Error fetching climate data:", error);
    throw new functions.https.HttpsError("internal", "Unable to fetch climate data.");
  }
});

export const getPostHarvestData = functions.https.onCall(async (data, context) => {
  try {
    const doc = await admin.firestore().collection("post_harvest").doc("latest").get();
    if (!doc.exists) {
      throw new functions.https.HttpsError("not-found", "Post-harvest data not found.");
    }
    return doc.data();
  } catch (error) {
    console.error("Error fetching post-harvest data:", error);
    throw new functions.https.HttpsError("internal", "Unable to fetch post-harvest data.");
  }
});
