const https = require('https');
const querystring = require('querystring');

const ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID || 'ACmock_sid';
const AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN || 'mock_token';
const FROM_NUMBER = process.env.TWILIO_FROM_NUMBER || '+1234567890';

/**
 * Dispatch an SMS notification using Twilio.
 * Uses native https module to avoid installation dependencies.
 *
 * @param {string} to - Destination phone number (e.g., "+94771234567")
 * @param {string} body - Message body
 */
async function sendSms(to, body) {
  if (!to) return { success: false, error: 'Phone number is missing.' };

  // Fallback if environment config is missing
  if (ACCOUNT_SID.startsWith('ACmock_sid') || ACCOUNT_SID === 'mock_token') {
    console.log(`[Twilio SMS Simulation] To: ${to} | Body: ${body}`);
    return { success: true, simulated: true };
  }

  return new Promise((resolve) => {
    const postData = querystring.stringify({
      To: to,
      From: FROM_NUMBER,
      Body: body
    });

    const options = {
      hostname: 'api.twilio.com',
      port: 443,
      path: `/2010-04-01/Accounts/${ACCOUNT_SID}/Messages.json`,
      method: 'POST',
      auth: `${ACCOUNT_SID}:${AUTH_TOKEN}`,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => {
        responseBody += chunk;
      });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ success: true, data: JSON.parse(responseBody) });
        } else {
          console.warn(`Twilio API error HTTP ${res.statusCode}: ${responseBody}`);
          resolve({ success: false, error: responseBody });
        }
      });
    });

    req.on('error', (err) => {
      console.error('Twilio request error:', err);
      resolve({ success: false, error: err.message });
    });

    req.write(postData);
    req.end();
  });
}

module.exports = {
  sendSms
};
