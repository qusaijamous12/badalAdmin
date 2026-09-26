import {initializeApp, applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';

const email = 'admin@gmail.com';
const password = process.env.BADAL_ADMIN_PASSWORD;
if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  throw new Error('Set GOOGLE_APPLICATION_CREDENTIALS to a Firebase service account JSON file.');
}
if (!password || password.length < 6) {
  throw new Error('Set BADAL_ADMIN_PASSWORD to the desired password (at least 6 characters).');
}

initializeApp({credential: applicationDefault(), projectId: 'badal-c59cb'});
const auth = getAuth();
let user;
try {
  user = await auth.getUserByEmail(email);
  user = await auth.updateUser(user.uid, {password});
} catch (error) {
  if (error.code !== 'auth/user-not-found') throw error;
  user = await auth.createUser({email, password});
}
await auth.setCustomUserClaims(user.uid, {...user.customClaims, admin: true});
console.log(`Admin account ready: ${email} (UID: ${user.uid}). Sign out and in again if already signed in.`);
