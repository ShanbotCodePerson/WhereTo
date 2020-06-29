
// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access Cloud Firestore.
const admin = require('firebase-admin');
admin.initializeApp();

// exports.voteReceived = functions.firestore.document('vote/{voteID}').onCreate(async (snapshot, context) => {

  // const db = admin.firestore();
  //
  // console.log('This has happened');
  // const votingSessionID = snapshot.data()['votingSessionID'];
  // console.log(`voting session id is ${votingSessionID}`);
  //
  // const votingSessionData = await db.collection('votingSession').where('uuid', '==', votingSessionID).get();
  // if (votingSessionData.empty) {
  //   console.log('no data found');
  //   return;
  // }
  // votingSessionData.forEach(doc => {
  //   console.log(doc);
  //   console.log(doc.fieldsProto);
  //   console.log(doc.fieldsProto['uuid']);
  // });
  //
  // return(null);
  // });
