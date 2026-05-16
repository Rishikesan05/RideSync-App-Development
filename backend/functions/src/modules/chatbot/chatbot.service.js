const dialogflow = require('@google-cloud/dialogflow');
const uuid = require('uuid');

/**
 * RideSync - Chatbot Service
 * Communicates with Google Dialogflow ES to process natural language queries.
 */

// If environment variables are not set properly, provide an actionable error
const projectId = process.env.DIALOGFLOW_PROJECT_ID || process.env.FIREBASE_PROJECT_ID;

if (!projectId && process.env.NODE_ENV === 'production') {
  console.warn('DIALOGFLOW_PROJECT_ID is not set in environment variables.');
}

// A session client handles communication with the Dialogflow API
// It automatically looks for GOOGLE_APPLICATION_CREDENTIALS in the env
let sessionClient;
try {
  sessionClient = new dialogflow.SessionsClient();
} catch (error) {
  console.error("Failed to initialize Dialogflow SessionsClient:", error.message);
  // We'll throw the error gracefully when a user actually tries to send a message
}

/**
 * Send a text message to the Dialogflow agent and get the response.
 *
 * @param {string} sessionId - A unique identifier for the conversation (e.g., User UID)
 * @param {string} text - The natural language message from the user
 * @param {string} languageCode - Language (e.g., 'en-US')
 * @returns {Object} - The parsed response and intent data
 */
exports.detectIntent = async (sessionId, text, languageCode = 'en-US') => {
  if (!sessionClient) {
    throw new Error('Chatbot service is currently unavailable. Dialogflow credentials may be missing.');
  }

  // Define the session path (Project ID + Session ID)
  // We fallback to a generic project ID string if undefined so the server doesn't crash on boot,
  // but it will fail on execution if truly invalid.
  const sessionPath = sessionClient.projectAgentSessionPath(
    projectId || 'ridesync-agent', 
    sessionId
  );

  // The request object
  const request = {
    session: sessionPath,
    queryInput: {
      text: {
        text: text,
        languageCode: languageCode,
      },
    },
  };

  try {
    // Send request and log result
    const responses = await sessionClient.detectIntent(request);
    const result = responses[0].queryResult;

    return {
      fulfillmentText: result.fulfillmentText,
      intent: result.intent ? result.intent.displayName : 'Unknown',
      confidence: result.intentDetectionConfidence,
      action: result.action,
      parameters: result.parameters && result.parameters.fields ? 
                  this._parseDialogflowParameters(result.parameters.fields) : {}
    };
  } catch (error) {
    console.error('Dialogflow API Error:', error);
    if (error.message.includes('Could not load the default credentials')) {
      throw new Error('Server configuration error: GOOGLE_APPLICATION_CREDENTIALS not found.');
    }
    throw error;
  }
};

/**
 * Helper to flatten Dialogflow's nested Protobuf parameter structures
 */
exports._parseDialogflowParameters = (fields) => {
  const params = {};
  for (const [key, value] of Object.entries(fields)) {
    // Determine the type of the struct value
    if (value.kind === 'stringValue') params[key] = value.stringValue;
    else if (value.kind === 'numberValue') params[key] = value.numberValue;
    else if (value.kind === 'boolValue') params[key] = value.boolValue;
    else if (value.kind === 'listValue') {
      params[key] = value.listValue.values.map(v => v.stringValue || v.numberValue || null);
    } else {
      params[key] = null;
    }
  }
  return params;
};
