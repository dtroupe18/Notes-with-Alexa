'use strict';
let Alexa = require('alexa-sdk');
let firebase = require('firebase');
let request = require('request');
require('firebase/database');

let smallImageURL = 'https://s3.amazonaws.com/trumpquotes/NoteswithAlexa+iconSmall.png';
let largeImageURL = 'https://s3.amazonaws.com/trumpquotes/NoteswithAlexa+iconLarge.png';
let appID = undefined;
let skillName = 'Notes';

const helpMessage = 'I can help you write down notes. To create a new note say something like, create shopping list.' +
    ' To add an item to a list say something like, add cheese to shopping list. I can read a list if you say, read ' +
    'shopping list. I can remove items from a list if you say, remove eggs from shopping list. I can tell you what notes ' +
    'you have if you say what notes do I have';

const helpPrompt = 'What can I help you with?';

// Firebase config
let firebaseConfig = {
    apiKey: "",
    authDomain: "",
    databaseURL: "",
    projectId: "",
    storageBucket: "",
    messagingSenderId: ""
};

firebase.initializeApp(firebaseConfig);
let database = firebase.database();
var listNames = [];


exports.handler = function(event, context, callback) {
    let alexa = Alexa.handler(event, context);
    alexa.appId = appID;
    console.log("appId: " + appID);

    // If the user hasn't linked their amazon account inform
    // them that they need to do that first
    //
    if (event.session.user.accessToken === undefined) {
        alexa.emit(':tellWithLinkAccountCard',
            'to start using this skill, please use ' +
            'the Alexa companion app to authenticate on Amazon');
        return;
    }

    // No user is signed in
    // Fetch the user profile from amazon
    //
    let amazonProfileURL = 'https://api.amazon.com/user/profile?access_token=';
    amazonProfileURL += event.session.user.accessToken;

    request(amazonProfileURL, function(error, response, body) {
        if (response.statusCode === 200) {
            let profile = JSON.parse(body);
            // Sign into Firebase
            //
            firebase.auth().signInWithEmailAndPassword(profile.email, profile.user_id).then(function() {
                // Sign in was successful
                //
                console.log("Sign in worked");
                alexa.registerHandlers(handlers);
                alexa.execute();
            }).catch(function(error) {
                // Handle Errors here.
                let errorCode = error.code;
                console.log("Firebase sign in failed");
                console.log("error code: " + errorCode);
                let errorMessage = error.message;
                console.log("error message: " + errorMessage);

                // create an account because they don't have one
                //
                firebase.auth().createUserWithEmailAndPassword(profile.email, profile.user_id).then(function() {
                    // Account successfully created
                    //
                    alexa.registerHandlers(handlers);
                    alexa.execute();
                }).catch(function(error) {
                    // Handle Error
                    //
                    let errorCode = error.code;
                    console.log("error code: " + errorCode);
                    let errorMessage = error.message;
                    console.log("error message: " + errorMessage);
                });
            });
        } else {
            alexa.emit(':tell', "Hello, I can't connect to Amazon Profile Service right now, try again later");
        }
    });
};

let handlers = {
    'LaunchRequest': function () {
        this.emit('WelcomeIntent');
    },

    'WelcomeIntent': function () {
        let user = firebase.auth().currentUser;

        if (user) {
            let uid = user.uid;
            getListNames(uid);
        }

        let speechOutput = "Welcome to iOS Notes. I can help you create and update notes that sync with your iphone. Say" +
            " something like create shopping list to get started.";
        this.emit(':ask', speechOutput);
        this.emit(':responseReady');
    },

    'Add': function() {
        // Sample utterance: add cheese to shopping list
        // This function gets the text translation
        // of the users speech
        //
        console.log("Add item Fired....");

        if(this.event.request.intent.slots.UserAddSpeech.value) {

            let userSpeech = this.event.request.intent.slots.UserAddSpeech.value;
            console.log("user speech: " + userSpeech);

            // We need to remove the first word from the users speech because
            // it will always be the intent word (i.e. "add" in this case)
            //
            let editedUserSpeech = userSpeech.substring(userSpeech.indexOf(" ") + 1, userSpeech.length).toLowerCase();
            console.log("Add intent edited speech: " + editedUserSpeech);

            // Find out what note we are supposed to add this item to
            //
            let noteName = undefined;

            listNames.forEach(function (value) {
                console.log("value: " + value);

                let lowerCase = String(value).toLowerCase();

                if (editedUserSpeech.indexOf(lowerCase) !== -1) {
                    // QWE: Do something about duplicates
                    //
                    noteName = value;
                    console.log("noteName: " + noteName);
                }
            });

            if (noteName === undefined) {
                this.response.speak("I can't find the note you're looking to update. Please try again, remember to" +
                    " say something like, Add milk to shopping list");
                this.response.shouldEndSession(false);
                this.emit(':responseReady');
            }

            let itemName = getItemTextOnly(editedUserSpeech);
            let cardText = itemName + " added to " + noteName;

            // Query start
            //
            // addItemToNoteInFirebase(noteName, itemName);
            let user;
            let uid;
            let speechOutput;

            console.log("updating note " + noteName + " by adding " + itemName);

            user = firebase.auth().currentUser;

            if (!user) {
                this.response.speak("Something went wrong I am unable to access your account. Please try again");
                this.response.shouldEndSession(false);
                this.emit(':responseReady');
            }

            uid = user.uid;
            database.ref('notes/' + uid).orderByChild('noteTitle').equalTo(noteName).once('value').then((snap) => {
                let additionalText;
                let key;

                snap.forEach(function (childSnapshot) {
                    let data = childSnapshot.val();
                    additionalText = data.additionalText;
                    console.log("additional text: " + additionalText);
                    key = data.noteId;
                    console.log("key: " + key);
                });

                if (key) {
                    // New items are added on the next line
                    //
                    if (!additionalText) {
                        additionalText = "\n";
                    }
                    additionalText += '\n';
                    additionalText += capitalizeFirstLetter(itemName);

                    let date = new Date();
                    let timestamp = date.getTime();

                    database.ref('/notes/' + uid + '/' + key).update({
                        additionalText: additionalText,
                        timestamp: timestamp
                    }).then(() => {
                        console.log("Add worked");
                        speechOutput = itemName + " added to " + noteName;
                        this.response.speak(speechOutput);
                        this.response.cardRenderer(skillName, speechOutput, {smallImageUrl: smallImageURL, largeImageUrl: largeImageURL});
                        this.response.shouldEndSession(true);
                        this.emit(':responseReady');
                    });
                }
                else {
                    console.log("!key");
                    console.log("key: " +  (key === undefined));
                    this.response.speak("Something went wrong I am unable to access your notes. Please try again");
                    this.response.shouldEndSession(false);
                    this.emit(':responseReady');
                }
            });
        }
        else {
            // user text is null
            //
            console.log("else case for add intent");
            console.log("slots: ", this.event.request.intent.slots);
            let speechOutput = "I did not understand your statement";
            let reprompt = "please tell me again";
            this.emit(':ask', speechOutput, reprompt);
        }
    },

    'Remove': function() {
        if (this.event.request.intent.slots.RemoveUserSpeech.value) {
            let userSpeech = this.event.request.intent.slots.RemoveUserSpeech.value;
            console.log("user speech: " + userSpeech);

            // We need to remove the first word from the users speech because
            // it will always be the intent word (i.e. "remove" in this case)
            //
            let editedUserSpeech = userSpeech.substring(userSpeech.indexOf(" ") + 1, userSpeech.length);
            console.log("edited user speech: " + editedUserSpeech);

            // Find out what note we are supposed to add this item to
            //
            let noteName = undefined;

            listNames.forEach(function (value) {
                console.log("value: " + value);

                let lowerCase = String(value).toLowerCase();

                if (editedUserSpeech.indexOf(lowerCase) !== -1) {
                    // QWE: Do something about duplicates
                    //
                    noteName = value;
                    console.log("noteName: " + noteName);
                }
            });

            if (noteName === undefined) {
                this.response.speak("I can't find the note you're looking to update. Please try again, remember to" +
                    " say something like, remove milk from shopping list");
                this.response.shouldEndSession(false);
                this.emit(':responseReady');
            }

            let itemName = getItemToRemove(editedUserSpeech);

            // let cardText = itemName + " removed from " + noteName;

            // Firebase Start
            //
            let user;
            let uid;
            let speechOutput;

            console.log("updating note " + noteName + " by removing " + itemName);

            user = firebase.auth().currentUser;

            if (!user) {
                this.response.speak("Something went wrong I am unable to access your account. Please try again");
                this.response.shouldEndSession(false);
                this.emit(':responseReady');
            }

            uid = user.uid;
            database.ref('notes/' + uid).orderByChild('noteTitle').equalTo(noteName).once('value').then((snap) => {
                let additionalText;
                let key;

                snap.forEach(function (childSnapshot) {
                    let data = childSnapshot.val();
                    additionalText = data.additionalText;
                    key = data.noteId;
                });

                if (additionalText && key) {
                    // Add the new item to the list
                    //
                    console.log("additionalText: " + additionalText);
                    console.log("text " + itemName);
                    let regularExpression = new RegExp(itemName,'i');
                    console.log("Regular Expression: " + regularExpression);

                    let result = additionalText.match(regularExpression);
                    console.log("result " + result);

                    if (!result) {
                        speechOutput = "I couldn't find " + itemName + ", in " + noteName;
                        console.log("!result.......");
                        this.response.speak(speechOutput);
                        this.response.cardRenderer(skillName, speechOutput, {smallImageUrl: smallImageURL, largeImageUrl: largeImageURL});
                        this.response.shouldEndSession(false);
                        this.emit(':responseReady');
                    }

                    if (result) {
                        console.log("result: " + result);

                        // update that note in firebase
                        //
                        let removed = additionalText.replace(result, '');
                        let date = new Date();
                        let timestamp = date.getTime();

                        database.ref('/notes/' + uid + '/' + key).update({
                            additionalText: removed,
                            timestamp: timestamp
                        }).then(() => {
                            console.log("Removed worked");
                            speechOutput = itemName + " removed from " + noteName;
                            this.response.speak(speechOutput);
                            this.response.cardRenderer(skillName, speechOutput, {smallImageUrl: smallImageURL, largeImageUrl: largeImageURL});
                            this.emit(':responseReady');
                        });
                    }
                }
                else {
                    this.response.speak("Something went wrong I am unable to access your notes. Please try again");
                    this.response.shouldEndSession(false);
                    this.emit(':responseReady');
                }
            });
        }
        else {
            // user text is null
            //
            console.log("else case for remove intent");
            console.log("slots: ", this.event.request.intent.slots);
            let speechOutput = "I did not understand your statement";
            let reprompt = "please tell me again";
            this.emit(':ask', speechOutput, reprompt);
        }
    },

    'GetNoteNames': function() {
        // Sample utterance: what notes / lists do I have
        // Get the title of each note and read it back to the user
        //
        let user = firebase.auth().currentUser;
        let listNamesToRead = [];

        if (user) {
            let uid = user.uid;
            this.response.shouldEndSession(false);
            database.ref('notes/' + uid).orderByKey().once('value').then((snap) => {
                console.log("notes snap: " + snap.val());

                snap.forEach(function (childSnapshot) {
                    let data = childSnapshot.val();
                    let listName = data.noteTitle;
                    console.log("note name: " + listName);
                    listNamesToRead.push(listName);
                });
            }).then(() => {
                // Read the note names to the user
                //
                let speechOutput = "You have the following notes, ";
                listNamesToRead.forEach(function(value) {
                    console.log("List name: " + value);
                    speechOutput += value + ", ";
                });

                this.response.speak(speechOutput + " how can I help you?");
                this.response.shouldEndSession(false);
                this.emit(':responseReady');
            });
        }
        else {
            // Error no user
            //
            let speechOutput = "Something went wrong I am unable to find your lists. Please try again";
            this.response.shouldEndSession(false);
            this.response.speak(speechOutput);
            this.emit(':responseReady');
        }
    },

    'Read': function() {
        // Get the note name from the user's speech and load that list
        //
        console.log("Read Fired....");
        let user = firebase.auth().currentUser;

        if (!user) {
            let speechOutput = "I'm having trouble connecting to your account. Please try again";
            this.emit(':ask', speechOutput);
        }

        if(this.event.request.intent.slots.UserListName.value) {

            let userSpeech = this.event.request.intent.slots.UserListName.value;
            console.log("user speech: " + userSpeech);

            // We need to remove the first word from the users speech because
            // it will always be the intent word (i.e. "read" in this case)
            //
            let editedUserSpeech = userSpeech.substring(userSpeech.indexOf(" ") + 1, userSpeech.length).toLowerCase();
            console.log("read intent edited speech: " + editedUserSpeech);

            // Find out what note we are supposed to add this item to
            //
            let noteName = undefined;

            listNames.forEach(function (value) {
                console.log("value: " + value);

                let lowerCase = String(value).toLowerCase();

                if (editedUserSpeech.indexOf(lowerCase) !== -1) {
                    // QWE: Do something about duplicates
                    //
                    noteName = value;
                    console.log("noteName: " + noteName);
                }
            });

            if (noteName === undefined) {
                this.response.speak("I can't find the note you're looking for. Please try again, remember to" +
                    " say something like, read shopping list");
                this.response.shouldEndSession(false);
                this.emit(':responseReady');
            }

            // Query starts
            //
            let noteText;
            let textToRead;

            console.log("Querying with noteName: " + noteName);

            database.ref('notes/' + user.uid).orderByChild('noteTitle').equalTo(noteName).once('value').then( (snap) => {
                    console.log(snap.val());

                    snap.forEach(function (childSnapshot) {
                        let data = childSnapshot.val();
                        let firstLine = data.firstLine;
                        let text = data.additionalText;

                        // Create a string Alexa can read
                        //
                        noteText = firstLine;
                        if (text !== undefined) {
                            noteText += text;
                        }

                        let search = '\n';

                        // Add a comma to slow down Alexa's reading
                        //
                        let replace = ', ';
                        textToRead = noteText.split(search).join(replace);
                        console.log("FullText: " + textToRead);
                    });
            }).then(() => {
                // Record this list to a card
                //
                if (!noteText || !textToRead) {
                    let speechOutput = "I'm having trouble connecting to your account. Please try again";
                    this.emit(':ask', speechOutput);
                }

                this.response.cardRenderer(skillName, noteText, {smallImageUrl: smallImageURL, largeImageUrl: largeImageURL});

                // Read list to user
                //
                this.response.speak("Reading " + textToRead);
                this.emit(':responseReady');
            });
        }
        else {
            // UserListName is null
            //
            let speechOutput = "I did not understand your statement";
            let reprompt = "please tell me again";
            this.emit(':ask', speechOutput, reprompt);
        }
    },

    'CreateList': function() {
        console.log("CreateList Fired....");
        let user = firebase.auth().currentUser;

        if (!user) {
            let speechOutput = "I'm having trouble connecting to your account. Please try again";
            this.emit(':ask', speechOutput);
        }

        if(this.event.request.intent.slots.NewListName.value) {

            let userSpeech = this.event.request.intent.slots.NewListName.value;
            console.log("user speech: " + userSpeech);

            // We need to remove the first word from the users speech because
            // it will always be the intent word (i.e. "create" in this case)
            //
            let editedUserSpeech = userSpeech.substring(userSpeech.indexOf(" ") + 1, userSpeech.length);
            console.log("edited speech: " + editedUserSpeech);

            // Create this note in Firebase
            //
            let key = database.ref('notes/' + user.uid).push().key;
            let d = new Date();
            let ms = d.getTime();
            let speechOutput;

            let lowercase = String(editedUserSpeech).toLowerCase();

            database.ref('notes/' + user.uid + '/' + key).set({
                additionalText: "\n",
                firstLine: capitalizeFirstLetter(editedUserSpeech),
                noteId: key,
                noteTitle: lowercase,
                timestamp: ms,
            }, function (error) {
                if (error) {
                    console.log(error);
                    speechOutput = "There was an error creating your note. Please" +
                        " try again.";
                }
                else {
                    listNames.push(lowercase);
                    console.log("new note successfully created");
                    speechOutput = "I created " + lowercase + " for you. ";
                    console.log(speechOutput);
                }
            }).then(() => {
                this.response.cardRenderer(skillName, speechOutput, {smallImageUrl: smallImageURL, largeImageUrl: largeImageURL});
                speechOutput += " Would you like to add something to this list?";
                this.response.shouldEndSession(false);
                this.emit(':ask', speechOutput);
                console.log("Finished creating new note");
            });
        }
    },

    'AMAZON.HelpIntent': function () {
        this.response.shouldEndSession(false);
        this.emit(':ask', helpMessage, helpPrompt);
    },

    'AMAZON.CancelIntent': function () {
        this.response.shouldEndSession(true);
        this.emit(':tell', 'Goodbye!');
    },

    'AMAZON.StopIntent': function () {
        this.response.shouldEndSession(true);
        this.emit(':tell', 'Goodbye!');
    },

    'SessionEndedRequest': function () {
        this.response.shouldEndSession(true);
        this.response.speak('Goodbye!');
        console.log(`Session ended: ${this.event.request.reason}`);
    },

    'Unhandled': function () {
        this.attributes.speechOutput = this.t(helpMessage);
        this.attributes.repromptSpeech = this.t(helpPrompt);
        this.response.speak(this.attributes.speechOutput).listen(this.attributes.repromptSpeech);
        this.response.shouldEndSession(true);
        this.emit(':responseReady');
    },
};

function getListNames(uid) {
    database.ref('notes/' + uid).orderByKey().once('value').then((snap) => {
        console.log("notes snap: " + snap.val());

        if (snap.exists()) {
            listNames = [];
            snap.forEach(function (childSnapshot) {
                let data = childSnapshot.val();
                let listName = data.noteTitle;
                console.log("note name: " + listName);
                listNames.push(listName);
            });
        }
    });
}

function addItemToNoteInFirebase(noteName, text) {
    // This function is going to be rather elaborate
    //
    // 1. Get the additional text from the note with noteName
    // 2. Add "\n" + text to it
    // 3. Update the notes timestamp
    // 3. Upload the string and timestamp into that note
    let user;
    let uid;
    console.log("updating note " + noteName + " with " + text);

    user = firebase.auth().currentUser;

    if (!user) {
        console.log("upload failed because there is no user");
        return;
    }
    uid = user.uid;
    console.log("uid: " + uid);

    database.ref('notes/' + uid).orderByChild('noteTitle').equalTo(noteName).once('value').then((snap) => {
        console.log(snap.val());

        snap.forEach(function (childSnapshot) {
            let data = childSnapshot.val();
            let additionalText = data.additionalText;
            let key = childSnapshot.key;
            // Add the new item to the list
            //
            additionalText += '\n' + capitalizeFirstLetter(text);

            // update that note in firebase
            //
            database.ref('/notes/' + uid + '/' + key).update({additionalText: additionalText});
            let date = new Date();
            let timestamp = date.getTime();
            database.ref('/notes/' + uid + '/' + key).update({timestamp: timestamp});
            // Done
            //
        })
    });
}

function getItemTextOnly(fullText) {

    if (fullText.indexOf('to') !== -1) {
        let split = fullText.split('to');
        // take everything before to
        //
        return capitalizeFirstLetter(split[0]);
    }

}

function getItemToRemove(string) {
    if (string.indexOf('from') !== -1) {
        // take everything before from
        //
        let split = string.split('from');

        return split[0].replace(/\s+$/, '');
    }
}

function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}
