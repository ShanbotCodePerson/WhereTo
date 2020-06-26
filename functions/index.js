
// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access Cloud Firestore.
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

exports.voteReceived = functions.firestore.document('vote/{voteID}').onCreate((snapshot, context) => {
  console.log('This has happened');
  console.log(`data is ${snapshot.data()}`);
  console.log(`voting session id is ${snapshot.data()['votingSessionID']}`);

  return(null);
    //
    // const text = snapshot.data().userID;
    // const payload = {
    //   notification: {
    //     title: `${snapshot.data().userID} voted`,
    //     body: 'This is just a test'
    //   }
    // };
    //
    // // Get the list of device tokens.
    // const allTokens = await admin.firestore().collection('fcmTokens').get();
    // const tokens = [];
    // allTokens.forEach((tokenDoc) => {
    //   tokens.push(tokenDoc.id);
    // });
    //
    // if (tokens.length > 0) {
    //   // Send notifications to all tokens.
    //   const response = await admin.messaging().sendToDevice(tokens, payload);
    //   await cleanupTokens(response, tokens);
    //   console.log('Notifications have been sent and tokens cleaned up.');
    // }
  });
