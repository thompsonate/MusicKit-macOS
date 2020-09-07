// This is a demo of generating a developer token from your private key

const jwt = require('jsonwebtoken');
const fs = require('fs');

const privateKey = fs.readFileSync('YOUR_PRIVATE_KEY.p8').toString();

const now = Math.floor(Date.now() / 1000);
const sixMonths = now + 15777000;

var token = jwt.sign({ 
    iss: 'YOUR_TEAM_ID',
    iat: now, 
    exp: sixMonths
}, privateKey, { algorithm: 'ES256', keyid: 'YOUR_KEY_ID' });

console.log('Token expires on ' + new Date(sixMonths * 1000).toUTCString());
console.log(token);
